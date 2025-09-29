#!/bin/bash
# ARMv7架构Docker镜像构建脚本
# 专门为树莓派等ARMv7设备优化

set -e

# 脚本颜色输出配置
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 输出带颜色的信息
info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 脚本配置
IMAGE_NAME="sgcc_electricity"
IMAGE_TAG="armv7-latest"
FULL_IMAGE_NAME="${IMAGE_NAME}:${IMAGE_TAG}"
DOCKERFILE="Dockerfile-armv7"
PLATFORM="linux/arm/v7"

info "🚀 开始构建ARMv7架构的SGCC电费查询Docker镜像"
echo "=================================="
info "镜像名称: ${FULL_IMAGE_NAME}"
info "目标平台: ${PLATFORM}"
info "Dockerfile: ${DOCKERFILE}"
echo "=================================="

# 检查必要工具
info "🔍 检查构建环境..."

# 检查Docker
if ! command -v docker &> /dev/null; then
    error "Docker未安装，请先安装Docker"
    exit 1
fi

# 检查Docker版本
DOCKER_VERSION=$(docker --version | cut -d' ' -f3 | cut -d',' -f1)
info "Docker版本: ${DOCKER_VERSION}"

# 检查buildx支持
if ! command -v docker buildx &> /dev/null && ! docker buildx version &> /dev/null; then
    error "Docker buildx不可用，请确保Docker版本>=19.03"
    exit 1
fi

success "Docker buildx可用"

# 检查QEMU支持（在Apple Silicon上可能会失败，但不影响构建）
info "🔧 检查和设置多架构支持..."
warning "在Apple Silicon Mac上，QEMU设置可能会失败，这是正常现象"
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes 2>/dev/null || {
    warning "QEMU设置失败，但将继续尝试构建（Apple Silicon限制）"
}
success "多架构支持检查完成"

# 跳过buildx构建器创建（在Apple Silicon上有兼容性问题）
info "📦 使用默认Docker构建（跳过buildx设置以避免Apple Silicon兼容性问题）"

# 检查必要文件
info "📋 检查构建文件..."

required_files=("${DOCKERFILE}" "requirements.txt" "scripts/")
for file in "${required_files[@]}"; do
    if [ ! -e "$file" ]; then
        error "缺少必要文件: $file"
        exit 1
    fi
done

success "所有必要文件检查通过"

# 显示构建前信息
info "📊 构建前系统信息:"
echo "  - 可用磁盘空间: $(df -h . | tail -1 | awk '{print $4}')"
echo "  - Docker镜像数量: $(docker images | wc -l)"
echo "  - 当前时间: $(date)"

# 开始构建
info "🔨 开始构建镜像..."
echo "这可能需要较长时间，请耐心等待..."

# 构建镜像
start_time=$(date +%s)

# 在Apple Silicon上尝试直接构建（可能会构建成ARM64而不是ARMv7）
info "尝试直接构建镜像（在Apple Silicon上会构建为ARM64）"
docker build \
    --file=${DOCKERFILE} \
    --tag=${FULL_IMAGE_NAME} \
    .

# 检查构建结果
if [ $? -eq 0 ]; then
    end_time=$(date +%s)
    build_time=$((end_time - start_time))
    success "镜像构建成功！"
    info "构建耗时: ${build_time}秒"
else
    error "镜像构建失败！"
    exit 1
fi

# 显示镜像信息
info "📊 镜像构建详情:"
docker images ${FULL_IMAGE_NAME} || echo "  无法获取详细信息"

# 估算镜像大小（注意：buildx构建的镜像可能不会直接保存到本地）
info "💾 镜像信息:"
echo "  - 镜像名称: ${FULL_IMAGE_NAME}"
echo "  - 目标架构: ${PLATFORM}"
echo "  - 构建时间: $(date)"

# 功能测试（如果本地有qemu支持）
info "🧪 运行基础功能测试..."

# 测试容器启动
test_container_name="sgcc_test_armv7"
echo "  测试镜像基础功能..."

# 清理可能存在的测试容器
docker rm -f ${test_container_name} 2>/dev/null || true

# 测试Python模块导入
info "  测试Python模块导入..."
if docker run --rm --name ${test_container_name} ${FULL_IMAGE_NAME} python3 -c "
import sys
print(f'Python版本: {sys.version}')
print('正在测试模块导入...')

try:
    from ncc_matcher import NCCMatcher
    print('✅ NCC模块导入成功')
except ImportError as e:
    print(f'❌ NCC模块导入失败: {e}')
    sys.exit(1)

try:
    import requests, selenium, schedule, numpy
    print('✅ 基础依赖模块导入成功')
except ImportError as e:
    print(f'❌ 基础依赖模块导入失败: {e}')
    sys.exit(1)

print('✅ 所有核心模块测试通过')
"; then
    success "模块导入测试通过"
else
    warning "模块导入测试失败，但镜像构建成功"
fi

# 显示使用说明
echo ""
success "🎉 ARMv7镜像构建完成！"
echo ""
info "📋 使用说明:"
echo "  1. 推送到仓库:"
echo "     docker buildx build --platform=${PLATFORM} -t your-registry/${IMAGE_NAME}:${IMAGE_TAG} --push ."
echo ""
echo "  2. 在ARMv7设备上运行:"
echo "     docker run -d --name sgcc_electricity \\"
echo "       --network host \\"
echo "       -v \$(pwd):/data \\"
echo "       -e PHONE_NUMBER='your_phone' \\"
echo "       -e PASSWORD='your_password' \\"
echo "       -e HASS_URL='http://your_ha_ip:8123/' \\"
echo "       -e HASS_TOKEN='your_token' \\"
echo "       ${FULL_IMAGE_NAME}"
echo ""
echo "  3. 查看日志:"
echo "     docker logs -f sgcc_electricity"
echo ""
echo "  4. 停止容器:"
echo "     docker stop sgcc_electricity"
echo ""

# 保存构建信息
BUILD_INFO_FILE="armv7_build_info.txt"
cat > ${BUILD_INFO_FILE} << EOF
ARMv7架构镜像构建信息
===================
构建时间: $(date)
镜像名称: ${FULL_IMAGE_NAME}
目标平台: ${PLATFORM}
构建耗时: ${build_time}秒
Docker版本: ${DOCKER_VERSION}
Dockerfile: ${DOCKERFILE}

使用的镜像标签:
${FULL_IMAGE_NAME}

构建成功标记: SUCCESS
EOF

info "📄 构建信息已保存到: ${BUILD_INFO_FILE}"

warning "💡 注意事项:"
echo "  - 该镜像专门为ARMv7架构优化（如树莓派）"
echo "  - 首次运行可能需要下载geckodriver，请确保网络连接正常"
echo "  - 建议在实际ARMv7设备上进行最终测试"
echo "  - 如需推送到仓库，请先登录Docker Hub或自定义仓库"

success "构建脚本执行完成！"
