#!/bin/bash
# 构建优化的Docker镜像脚本

set -e

echo "🐳 开始构建优化的Docker镜像..."

# 设置变量
IMAGE_NAME="sgcc_electricity_optimized"
TAG="latest"
DOCKERFILE="Dockerfile-simple"

echo "📋 构建信息:"
echo "  镜像名称: ${IMAGE_NAME}:${TAG}"
echo "  Dockerfile: ${DOCKERFILE}"
echo ""

# 检查Dockerfile是否存在
if [ ! -f "$DOCKERFILE" ]; then
    echo "❌ 错误: Dockerfile不存在: $DOCKERFILE"
    exit 1
fi

# 检查requirements.txt是否存在
if [ ! -f "requirements.txt" ]; then
    echo "❌ 错误: requirements.txt不存在"
    exit 1
fi

# 检查scripts目录是否存在
if [ ! -d "scripts" ]; then
    echo "❌ 错误: scripts目录不存在"
    exit 1
fi

echo "✅ 所有必要文件检查通过"
echo ""

# 构建镜像
echo "🔨 开始构建Docker镜像..."
docker build -f "$DOCKERFILE" -t "${IMAGE_NAME}:${TAG}" .

if [ $? -eq 0 ]; then
    echo "✅ Docker镜像构建成功！"
else
    echo "❌ Docker镜像构建失败！"
    exit 1
fi

echo ""

# 显示镜像信息
echo "📊 镜像信息:"
docker images "${IMAGE_NAME}:${TAG}"

echo ""

# 显示镜像大小对比
echo "📈 大小对比:"
echo "  原始镜像: 1.15GB"
CURRENT_SIZE=$(docker images --format "table {{.Size}}" "${IMAGE_NAME}:${TAG}" | tail -n 1)
echo "  优化镜像: ${CURRENT_SIZE}"

echo ""

# 测试镜像功能
echo "🧪 测试镜像功能..."

# 测试NCC模块导入
echo "  测试NCC模块导入..."
docker run --rm "${IMAGE_NAME}:${TAG}" python3 -c "
from scripts.ncc_matcher import SliderCaptchaMatcher
print('✅ NCC模块导入成功')
"

if [ $? -eq 0 ]; then
    echo "✅ NCC模块测试通过"
else
    echo "❌ NCC模块测试失败"
    exit 1
fi

# 测试DataFetcher模块导入
echo "  测试DataFetcher模块导入..."
docker run --rm "${IMAGE_NAME}:${TAG}" python3 -c "
from scripts.data_fetcher import DataFetcher
print('✅ DataFetcher模块导入成功')
"

if [ $? -eq 0 ]; then
    echo "✅ DataFetcher模块测试通过"
else
    echo "❌ DataFetcher模块测试失败"
    exit 1
fi

echo ""

# 显示镜像层信息
echo "🔍 镜像层分析:"
docker history "${IMAGE_NAME}:${TAG}"

echo ""

# 显示镜像内容
echo "📁 镜像内容分析:"
docker run --rm "${IMAGE_NAME}:${TAG}" du -sh /* 2>/dev/null | sort -hr

echo ""

echo "🎉 构建完成！"
echo ""
echo "📋 使用说明:"
echo "  运行容器: docker run --rm ${IMAGE_NAME}:${TAG}"
echo "  后台运行: docker run -d --name sgcc_electricity ${IMAGE_NAME}:${TAG}"
echo "  查看日志: docker logs sgcc_electricity"
echo "  停止容器: docker stop sgcc_electricity"
echo ""
echo "💡 提示: 镜像已优化，移除了onnxruntime和captcha.onnx，使用NCC算法替代"
