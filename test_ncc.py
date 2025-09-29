
"""演示一下如何使用NCC 以及扣除透明背景寻找真实的模版，若是需要有幸被本项目采纳，希望可以在注释里面带上这个issue 的引用即可。

作者: shellvon
"""
import base64
import io
import numpy as np
from PIL import Image, ImageDraw
import logging

# 配置日志
_LOGGER = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

class NCCMatcherCLI:
    """
    使用归一化互相关 (NCC) 算法进行带透明度模板匹配的命令行工具。
    """
    
    def __init__(self):
        self.matcher = NCCMatcher()

    def process_images(self, template_base64_str: str, background_base64_str: str):
        """
        处理并匹配图像。
        """
        _LOGGER.info("正在处理模板...")
        try:
            # 1. 提取非透明部分作为最终模板，并获取 Y 坐标
            final_template_base64, found_y = self._extract_opaque_and_get_y(template_base64_str)
            if final_template_base64 is None:
                _LOGGER.error("模板处理失败，程序退出。")
                return

            _LOGGER.info(f"提取非透明部分成功。找到的第一个非透明像素Y坐标为: {found_y}")

            # 2. 找到最佳匹配位置
            x, y, confidence = self.matcher.find_best_match(final_template_base64, background_base64_str)
            
            # 3. 保存文件并输出结果
            self._save_and_output_results(
                final_template_base64, 
                background_base64_str, 
                x, y, 
                confidence,
                found_y
            )

        except Exception as e:
            _LOGGER.error(f"处理过程中发生错误: {e}")
            
    def _extract_opaque_and_get_y(self, template_base64: str) -> tuple:
        """
        从带有透明度的PNG模板中提取非透明区域的图像数据，并返回其base64和找到的Y坐标。因为Y也可以让我们后续查找提速。
        """
        try:
            template_img = Image.open(io.BytesIO(base64.b64decode(template_base64)))
            
            if template_img.mode != 'RGBA':
                _LOGGER.error("提供的模板图像不包含Alpha通道。")
                return None, None
                
            template_data = np.array(template_img)
            alpha_channel = template_data[:, :, 3]
            
            # 找到非透明像素的边界
            rows, cols = np.where(alpha_channel > 0)
            
            if len(rows) == 0 or len(cols) == 0:
                _LOGGER.warning("模板中没有非透明像素。")
                return None, None
                
            min_y, max_y = np.min(rows), np.max(rows)
            min_x, max_x = np.min(cols), np.max(cols)
            
            # 裁剪出非透明区域的RGB/RGBA数据
            # 这里为了保存透明度信息，我们保留RGBA模式
            opaque_img = template_img.crop((min_x, min_y, max_x + 1, max_y + 1))
            
            # 将裁剪后的图像重新编码为base64
            with io.BytesIO() as buffer:
                opaque_img.save(buffer, format='PNG')
                final_template_base64 = base64.b64encode(buffer.getvalue()).decode('utf-8')
            
            return final_template_base64, min_y
            
        except Exception as e:
            _LOGGER.error(f"提取非透明模板失败: {e}")
            return None, None

    def _save_and_output_results(self, final_template_base64: str, background_base64: str, 
                                 x: int, y: int, confidence: float, found_y: int):
        """
        保存所有相关文件并输出结果到控制台。
        """
        # 保存原始背景图
        bg_img = self.matcher._base64_to_image(background_base64)
        bg_img.save("background.png")
        _LOGGER.info("原始背景图已保存到 background.png")

        # 保存裁剪后的模板
        final_tmpl_img = self.matcher._base64_to_image(final_template_base64)
        final_tmpl_img.save("temp.png")
        _LOGGER.info("抠图后的模板已保存到 temp.png")
        
        print("\n========== 匹配结果 ==========")
        print(f"模板抠图后，第一个非透明像素的Y坐标: {found_y}")
        if x is not None and y is not None:
            print(f"找到最佳匹配位置: (x={x}, y={y})")
            print(f"NCC相关性: {confidence:.4f}")
            self.matcher.draw_match_rectangle(background_base64, x, y, final_template_base64, 'result.png')
        else:
            print("未找到最佳匹配位置。")
            
        print("================================")
        

class NCCMatcher:
    def _base64_to_image(self, base64_data: str) -> Image.Image:
        if base64_data.startswith('data:image/'):
            base64_data = base64_data.split(',')[1]
        image_data = base64.b64decode(base64_data)
        return Image.open(io.BytesIO(image_data))

    def _ncc_with_mask(self, window: np.ndarray, template: np.ndarray, mask: np.ndarray) -> float:
        window = window.astype(np.float64)
        template = template.astype(np.float64)
        
        masked_window = window * mask
        masked_template = template * mask
        
        valid_pixels = mask > 0
        if not np.any(valid_pixels):
            return 0
        
        window_mean = np.mean(masked_window[valid_pixels])
        template_mean = np.mean(masked_template[valid_pixels])
        
        diff_window = masked_window - window_mean
        diff_template = masked_template - template_mean
        
        numerator = np.sum(diff_window * diff_template)
        
        std_window = np.sqrt(np.sum(diff_window ** 2))
        std_template = np.sqrt(np.sum(diff_template ** 2))
        
        if std_window == 0 or std_template == 0:
            return 0
            
        correlation = numerator / (std_window * std_template)
        return correlation

    def find_best_match(self, template_base64: str, background_base64: str) -> tuple:
        try:
            template_img = self._base64_to_image(template_base64)
            background_img = self._base64_to_image(background_base64)

            if template_img.mode != 'RGBA':
                _LOGGER.error("模板图像不包含Alpha通道，无法进行带掩码的NCC匹配。")
                return None, None, None
            
            template_data = np.array(template_img)
            template_gray = template_data[:, :, 0:3].mean(axis=2).astype(np.uint8)
            template_mask = template_data[:, :, 3] / 255.0

            bg_data = np.array(background_img)
            if bg_data.ndim == 3:
                bg_gray = bg_data[:, :, 0:3].mean(axis=2).astype(np.uint8)
            else:
                bg_gray = bg_data
                
            bg_height, bg_width = bg_gray.shape
            tmpl_height, tmpl_width = template_gray.shape

            max_corr = -1.0
            best_x, best_y = -1, -1

            for y in range(bg_height - tmpl_height + 1):
                for x in range(bg_width - tmpl_width + 1):
                    window = bg_gray[y:y + tmpl_height, x:x + tmpl_width]
                    corr = self._ncc_with_mask(window, template_gray, template_mask)
                    
                    if corr > max_corr:
                        max_corr = corr
                        best_x, best_y = x, y

            _LOGGER.info(f"匹配完成。最佳位置: (x={best_x}, y={best_y}), NCC相关性: {max_corr:.4f}")
            
            return best_x, best_y, max_corr

        except Exception as e:
            _LOGGER.error(f"模板匹配失败: {e}")
            return None, None, None

    def draw_match_rectangle(self, background_base64: str, x: int, y: int, template_base64: str, output_path: str):
        if x is None or y is None:
            _LOGGER.warning("未找到匹配位置，跳过绘制。")
            return
        try:
            background_img = self._base64_to_image(background_base64)
            template_img = self._base64_to_image(template_base64)
            tmpl_width, tmpl_height = template_img.size
            
            draw = ImageDraw.Draw(background_img)
            draw.rectangle([x, y, x + tmpl_width, y + tmpl_height], outline="red", width=2)
            
            background_img.save(output_path)
            _LOGGER.info(f"绘制匹配结果图已保存到: {output_path}")

        except Exception as e:
            _LOGGER.error(f"绘制匹配矩形失败: {e}")

if __name__ == '__main__':
    cli = NCCMatcherCLI()
    template_base64_str = '....不要带前缀data:image/png;base64, 若有，请split(",")[1]'
    background_base64_str = '....'
    cli.process_images(template_base64_str, background_base64_str)