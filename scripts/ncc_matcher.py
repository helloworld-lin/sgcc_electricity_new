# -*- coding: utf-8 -*-
"""
基于归一化互相关(NCC)算法的滑块验证码识别模块
用于替换原有的ONNX模型，提供更轻量级的验证码识别解决方案

作者: AI Assistant
基于: test_ncc.py 中的NCC算法实现
"""

import base64
import io
import numpy as np
from PIL import Image, ImageDraw
import logging

# 配置日志
_LOGGER = logging.getLogger(__name__)

class NCCMatcher:
    """
    使用归一化互相关 (NCC) 算法进行滑块验证码识别的核心类
    通过模板匹配的方式找到滑块在背景图中的最佳位置
    """
    
    def __init__(self):
        """初始化NCC匹配器"""
        _LOGGER.info("NCC滑块验证码识别器初始化完成")
    
    def _base64_to_image(self, base64_data: str) -> Image.Image:
        """
        将base64编码的图片数据转换为PIL Image对象
        
        Args:
            base64_data: base64编码的图片数据，支持带或不带data:image/前缀
            
        Returns:
            PIL Image对象
        """
        # 移除可能存在的data:image/前缀
        if base64_data.startswith('data:image/'):
            base64_data = base64_data.split(',')[1]
        
        # 解码base64数据并转换为PIL Image
        image_data = base64.b64decode(base64_data)
        return Image.open(io.BytesIO(image_data))

    def _ncc_with_mask(self, window: np.ndarray, template: np.ndarray, mask: np.ndarray) -> float:
        """
        使用掩码进行归一化互相关计算
        
        Args:
            window: 背景图中的滑动窗口区域
            template: 模板图像
            mask: 掩码，用于忽略透明区域
            
        Returns:
            NCC相关性系数，范围[-1, 1]，越接近1表示匹配度越高
        """
        # 转换为浮点数以提高计算精度
        window = window.astype(np.float64)
        template = template.astype(np.float64)
        
        # 应用掩码，将透明区域设为0
        masked_window = window * mask
        masked_template = template * mask
        
        # 找到有效像素（非透明区域）
        valid_pixels = mask > 0
        if not np.any(valid_pixels):
            return 0  # 如果没有有效像素，返回0相关性
        
        # 计算均值
        window_mean = np.mean(masked_window[valid_pixels])
        template_mean = np.mean(masked_template[valid_pixels])
        
        # 计算与均值的差值
        diff_window = masked_window - window_mean
        diff_template = masked_template - template_mean
        
        # 计算分子：差值的内积
        numerator = np.sum(diff_window * diff_template)
        
        # 计算分母：标准差的乘积
        std_window = np.sqrt(np.sum(diff_window ** 2))
        std_template = np.sqrt(np.sum(diff_template ** 2))
        
        # 避免除零错误
        if std_window == 0 or std_template == 0:
            return 0
            
        # 计算归一化互相关系数
        correlation = numerator / (std_window * std_template)
        return correlation

    def _extract_slider_template(self, background_image: Image.Image) -> tuple:
        """
        从背景图中提取滑块模板
        
        这个方法假设滑块是背景图中最右侧的一个矩形区域
        在实际应用中，可能需要根据具体的验证码样式进行调整
        
        Args:
            background_image: 背景图像
            
        Returns:
            (template_image, template_mask): 提取的模板图像和对应的掩码
        """
        # 将图像转换为numpy数组
        img_array = np.array(background_image)
        
        # 如果是RGBA图像，提取alpha通道作为掩码
        if img_array.shape[2] == 4:
            alpha_channel = img_array[:, :, 3]
            # 创建掩码：alpha值大于0的区域为有效区域
            mask = (alpha_channel > 0).astype(np.float64)
        else:
            # 如果是RGB图像，创建全1掩码
            mask = np.ones((img_array.shape[0], img_array.shape[1]), dtype=np.float64)
        
        # 假设滑块在图像的右侧，提取右侧1/4区域作为模板
        height, width = img_array.shape[:2]
        template_width = width // 4
        
        # 提取右侧区域作为滑块模板
        template_region = img_array[:, -template_width:]
        template_mask = mask[:, -template_width:]
        
        # 转换为PIL Image
        if template_region.shape[2] == 4:
            template_image = Image.fromarray(template_region, 'RGBA')
        else:
            template_image = Image.fromarray(template_region, 'RGB')
        
        return template_image, template_mask

    def find_slider_position(self, background_image: Image.Image) -> int:
        """
        在背景图中找到滑块的最佳位置
        
        Args:
            background_image: 背景图像（PIL Image对象）
            
        Returns:
            滑块应该移动到的x坐标位置
        """
        try:
            # 提取滑块模板
            template_image, template_mask = self._extract_slider_template(background_image)
            
            # 将模板转换为灰度图像
            template_gray = np.array(template_image.convert('L'))
            
            # 将背景图像转换为灰度图像
            if background_image.mode == 'RGBA':
                background_gray = np.array(background_image.convert('L'))
            else:
                background_gray = np.array(background_image.convert('L'))
            
            # 获取图像尺寸
            bg_height, bg_width = background_gray.shape
            tmpl_height, tmpl_width = template_gray.shape
            
            # 初始化最佳匹配参数
            max_corr = -1.0
            best_x = -1
            
            # 在背景图中滑动模板，寻找最佳匹配位置
            for y in range(bg_height - tmpl_height + 1):
                for x in range(bg_width - tmpl_width + 1):
                    # 提取当前窗口
                    window = background_gray[y:y + tmpl_height, x:x + tmpl_width]
                    
                    # 计算NCC相关性
                    corr = self._ncc_with_mask(window, template_gray, template_mask)
                    
                    # 更新最佳匹配
                    if corr > max_corr:
                        max_corr = corr
                        best_x = x
            
            _LOGGER.info(f"滑块位置识别完成。最佳位置: x={best_x}, NCC相关性: {max_corr:.4f}")
            
            # 如果相关性太低，可能识别失败
            if max_corr < 0.3:  # 阈值可以根据实际情况调整
                _LOGGER.warning(f"NCC相关性较低({max_corr:.4f})，可能识别失败")
                return 0
            
            return best_x
            
        except Exception as e:
            _LOGGER.error(f"滑块位置识别失败: {e}")
            return 0

    def get_distance(self, image: Image.Image, draw: bool = False) -> int:
        """
        获取滑块需要移动的距离
        
        这是为了保持与原有ONNX接口的兼容性而设计的方法
        
        Args:
            image: 背景图像
            draw: 是否绘制识别结果（暂时未实现）
            
        Returns:
            滑块需要移动的距离（像素）
        """
        try:
            # 找到滑块位置
            slider_x = self.find_slider_position(image)
            
            # 计算移动距离（假设滑块初始位置在左侧）
            # 这里需要根据实际的验证码布局进行调整
            distance = slider_x
            
            if draw:
                # 可以在这里添加绘制识别结果的代码
                _LOGGER.info(f"识别结果: 滑块应移动到x={slider_x}位置")
            
            return distance
            
        except Exception as e:
            _LOGGER.error(f"获取滑块距离失败: {e}")
            return 0

    def draw_match_result(self, background_image: Image.Image, x: int, template_image: Image.Image, output_path: str = 'result.png'):
        """
        绘制匹配结果，在背景图上标记识别到的滑块位置
        
        Args:
            background_image: 背景图像
            x: 识别到的x坐标
            template_image: 模板图像
            output_path: 输出文件路径
        """
        try:
            if x is None or x < 0:
                _LOGGER.warning("无效的匹配位置，跳过绘制")
                return
                
            # 创建图像副本用于绘制
            result_img = background_image.copy()
            draw = ImageDraw.Draw(result_img)
            
            # 获取模板尺寸
            tmpl_width, tmpl_height = template_image.size
            
            # 绘制红色矩形框标记识别位置
            draw.rectangle([x, 0, x + tmpl_width, tmpl_height], outline="red", width=2)
            
            # 添加文本标注
            draw.text((x, 0), f'Slider: x={x}', fill="red")
            
            # 保存结果图像
            result_img.save(output_path)
            _LOGGER.info(f"匹配结果图已保存到: {output_path}")
            
        except Exception as e:
            _LOGGER.error(f"绘制匹配结果失败: {e}")


class SliderCaptchaMatcher:
    """
    滑块验证码识别器的主要接口类
    提供与原有ONNX类兼容的接口
    """
    
    def __init__(self, model_path: str = None):
        """
        初始化滑块验证码识别器
        
        Args:
            model_path: 模型路径（为了兼容性保留，但NCC算法不需要模型文件）
        """
        self.ncc_matcher = NCCMatcher()
        _LOGGER.info("滑块验证码识别器初始化完成（使用NCC算法）")
    
    def get_distance(self, image: Image.Image, draw: bool = False) -> int:
        """
        获取滑块需要移动的距离
        
        Args:
            image: 背景图像
            draw: 是否绘制识别结果
            
        Returns:
            滑块需要移动的距离（像素）
        """
        return self.ncc_matcher.get_distance(image, draw)


# 为了保持向后兼容性，创建一个ONNX类的别名
ONNX = SliderCaptchaMatcher

if __name__ == "__main__":
    # 测试代码
    logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
    
    # 创建识别器实例
    matcher = SliderCaptchaMatcher()
    
    # 测试图像路径
    img_path = "../assets/background.png"
    
    try:
        # 加载测试图像
        img = Image.open(img_path)
        print(f"加载测试图像: {img_path}")
        
        # 识别滑块位置
        distance = matcher.get_distance(img, draw=True)
        print(f"识别结果: 滑块需要移动 {distance} 像素")
        
    except Exception as e:
        print(f"测试失败: {e}")
