#!/bin/bash
# 快速Buildx设置脚本 - 适用于已有Docker的Linux系统

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }

info "🔧 快速设置Docker Buildx for ARMv7构建"

# 检查Docker
if ! command -v docker &> /dev/null; then
    echo "❌ Docker未安装，请先安装Docker"
    exit 1
fi

info "✅ Docker已安装: $(docker --version)"

# 检查Buildx
if ! docker buildx version &> /dev/null; then
    info "📦 安装Docker Buildx..."
    
    # 获取最新版本
    BUILDX_VERSION=$(curl -s https://api.github.com/repos/docker/buildx/releases/latest | grep tag_name | cut -d '"' -f 4)
    ARCH=$(uname -m)
    
    case $ARCH in
        x86_64) BUILDX_ARCH="linux-amd64" ;;
        aarch64|arm64) BUILDX_ARCH="linux-arm64" ;;
        armv7l) BUILDX_ARCH="linux-arm-v7" ;;
        *) echo "❌ 不支持的架构: $ARCH"; exit 1 ;;
    esac
    
    mkdir -p ~/.docker/cli-plugins
    curl -L "https://github.com/docker/buildx/releases/download/${BUILDX_VERSION}/buildx-${BUILDX_VERSION}.${BUILDX_ARCH}" \
        -o ~/.docker/cli-plugins/docker-buildx
    chmod +x ~/.docker/cli-plugins/docker-buildx
    
    success "Buildx安装完成: $(docker buildx version)"
else
    success "Buildx已可用: $(docker buildx version)"
fi

# 安装QEMU（根据发行版）
info "🔧 设置多架构支持..."

if command -v apt-get &> /dev/null; then
    sudo apt-get update && sudo apt-get install -y qemu qemu-user-static binfmt-support
elif command -v yum &> /dev/null; then
    sudo yum install -y qemu-user-static
elif command -v dnf &> /dev/null; then
    sudo dnf install -y qemu-user-static
else
    warning "请手动安装qemu-user-static包"
fi

# 注册QEMU
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
success "多架构支持已设置"

# 创建构建器
info "📦 创建ARMv7构建器..."
docker buildx create --name armv7-builder --platform linux/arm/v7 --use 2>/dev/null || {
    docker buildx rm armv7-builder 2>/dev/null || true
    docker buildx create --name armv7-builder --platform linux/arm/v7 --use
}

docker buildx inspect armv7-builder --bootstrap
success "构建器已准备就绪"

# 开始构建
if [ -f "Dockerfile-armv7" ] && [ -f "requirements.txt" ] && [ -d "scripts" ]; then
    info "🔨 开始构建ARMv7镜像..."
    
    docker buildx build \
        --platform linux/arm/v7 \
        --file Dockerfile-armv7 \
        --tag sgcc_electricity:armv7-latest \
        --load \
        --progress=plain \
        .
    
    if [ $? -eq 0 ]; then
        success "🎉 ARMv7镜像构建成功！"
        docker images sgcc_electricity:armv7-latest
        
        # 简单测试
        info "🧪 测试镜像..."
        docker run --rm sgcc_electricity:armv7-latest python3 -c "print('✅ ARMv7镜像可以正常运行')"
        
        echo ""
        info "📋 使用方法："
        echo "docker run -d --name sgcc_electricity \\"
        echo "  --network host \\"
        echo "  -v \$(pwd):/data \\"
        echo "  -e PHONE_NUMBER='your_phone' \\"
        echo "  -e PASSWORD='your_password' \\"
        echo "  sgcc_electricity:armv7-latest"
    else
        echo "❌ 构建失败"
        exit 1
    fi
else
    warning "在当前目录未找到必要文件，请确保有："
    echo "- Dockerfile-armv7"
    echo "- requirements.txt"  
    echo "- scripts/ 目录"
fi

success "设置完成！"
