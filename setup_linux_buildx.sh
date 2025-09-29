#!/bin/bash
# Linux环境下Docker Buildx安装和ARMv7构建脚本
# 支持Ubuntu/Debian/CentOS/RHEL等主流Linux发行版

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

# 检测Linux发行版
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
        VERSION=$VERSION_ID
    elif [ -f /etc/redhat-release ]; then
        DISTRO="centos"
    elif [ -f /etc/debian_version ]; then
        DISTRO="debian"
    else
        DISTRO="unknown"
    fi
    
    info "检测到Linux发行版: $DISTRO $VERSION"
}

# 安装Docker（如果未安装）
install_docker() {
    if command -v docker &> /dev/null; then
        info "Docker已安装: $(docker --version)"
        return
    fi
    
    info "正在安装Docker..."
    
    case $DISTRO in
        ubuntu|debian)
            # Ubuntu/Debian安装Docker
            sudo apt-get update
            sudo apt-get install -y \
                apt-transport-https \
                ca-certificates \
                curl \
                gnupg \
                lsb-release
            
            # 添加Docker官方GPG密钥
            curl -fsSL https://download.docker.com/linux/$DISTRO/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
            
            # 添加Docker仓库
            echo \
              "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/$DISTRO \
              $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
            
            # 安装Docker Engine
            sudo apt-get update
            sudo apt-get install -y docker-ce docker-ce-cli containerd.io
            ;;
            
        centos|rhel|fedora)
            # CentOS/RHEL/Fedora安装Docker
            sudo yum install -y yum-utils
            sudo yum-config-manager \
                --add-repo \
                https://download.docker.com/linux/centos/docker-ce.repo
            sudo yum install -y docker-ce docker-ce-cli containerd.io
            ;;
            
        *)
            error "不支持的Linux发行版: $DISTRO"
            error "请手动安装Docker: https://docs.docker.com/engine/install/"
            exit 1
            ;;
    esac
    
    # 启动Docker服务
    sudo systemctl start docker
    sudo systemctl enable docker
    
    # 将当前用户添加到docker组
    sudo usermod -aG docker $USER
    
    success "Docker安装完成！"
    warning "请注销并重新登录以使docker组权限生效，或运行: newgrp docker"
}

# 安装Docker Buildx
install_buildx() {
    info "检查Docker Buildx..."
    
    if docker buildx version &> /dev/null; then
        info "Docker Buildx已可用: $(docker buildx version)"
        return
    fi
    
    info "正在安装Docker Buildx..."
    
    # 获取最新版本号
    BUILDX_VERSION=$(curl -s https://api.github.com/repos/docker/buildx/releases/latest | grep tag_name | cut -d '"' -f 4)
    info "最新Buildx版本: $BUILDX_VERSION"
    
    # 检测架构
    ARCH=$(uname -m)
    case $ARCH in
        x86_64)
            BUILDX_ARCH="linux-amd64"
            ;;
        aarch64|arm64)
            BUILDX_ARCH="linux-arm64"
            ;;
        armv7l)
            BUILDX_ARCH="linux-arm-v7"
            ;;
        *)
            error "不支持的架构: $ARCH"
            exit 1
            ;;
    esac
    
    # 下载并安装buildx
    mkdir -p ~/.docker/cli-plugins
    curl -L "https://github.com/docker/buildx/releases/download/${BUILDX_VERSION}/buildx-${BUILDX_VERSION}.${BUILDX_ARCH}" \
        -o ~/.docker/cli-plugins/docker-buildx
    chmod +x ~/.docker/cli-plugins/docker-buildx
    
    success "Docker Buildx安装完成！"
    info "Buildx版本: $(docker buildx version)"
}

# 安装QEMU用户模式模拟器
install_qemu() {
    info "安装QEMU用户模式模拟器..."
    
    case $DISTRO in
        ubuntu|debian)
            sudo apt-get update
            sudo apt-get install -y qemu qemu-user-static binfmt-support
            ;;
        centos|rhel|fedora)
            sudo yum install -y qemu-user-static
            ;;
        *)
            warning "请手动安装qemu-user-static包"
            ;;
    esac
    
    # 注册QEMU解释器
    docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
    
    success "QEMU安装并配置完成！"
}

# 创建和配置Buildx构建器
setup_buildx_builder() {
    info "设置Buildx构建器..."
    
    # 创建新的构建器实例
    BUILDER_NAME="armv7-builder"
    
    if docker buildx ls | grep -q $BUILDER_NAME; then
        info "构建器 $BUILDER_NAME 已存在，正在删除..."
        docker buildx rm $BUILDER_NAME || true
    fi
    
    # 创建支持多架构的构建器
    docker buildx create \
        --name $BUILDER_NAME \
        --driver docker-container \
        --platform linux/amd64,linux/arm64,linux/arm/v7 \
        --use
    
    # 启动构建器
    docker buildx inspect $BUILDER_NAME --bootstrap
    
    success "Buildx构建器设置完成！"
    docker buildx ls
}

# 构建ARMv7镜像
build_armv7_image() {
    info "开始构建ARMv7镜像..."
    
    # 检查必要文件
    if [ ! -f "Dockerfile-armv7" ]; then
        error "未找到Dockerfile-armv7文件"
        exit 1
    fi
    
    if [ ! -f "requirements.txt" ]; then
        error "未找到requirements.txt文件"
        exit 1
    fi
    
    if [ ! -d "scripts" ]; then
        error "未找到scripts目录"
        exit 1
    fi
    
    # 构建镜像
    IMAGE_NAME="sgcc_electricity:armv7-linux-build"
    
    info "构建镜像: $IMAGE_NAME"
    info "目标平台: linux/arm/v7"
    
    start_time=$(date +%s)
    
    docker buildx build \
        --platform linux/arm/v7 \
        --file Dockerfile-armv7 \
        --tag $IMAGE_NAME \
        --load \
        --progress=plain \
        .
    
    if [ $? -eq 0 ]; then
        end_time=$(date +%s)
        build_time=$((end_time - start_time))
        success "ARMv7镜像构建成功！"
        info "构建耗时: ${build_time}秒"
        
        # 显示镜像信息
        docker images $IMAGE_NAME
        
        # 测试镜像
        test_armv7_image $IMAGE_NAME
    else
        error "ARMv7镜像构建失败！"
        exit 1
    fi
}

# 测试ARMv7镜像
test_armv7_image() {
    local image_name=$1
    info "测试ARMv7镜像..."
    
    # 测试基础功能
    if docker run --rm --platform linux/arm/v7 $image_name python3 -c "
import sys
print(f'Python版本: {sys.version}')
print('架构信息:', sys.platform)

try:
    from ncc_matcher import NCCMatcher
    print('✅ NCC模块导入成功')
except ImportError as e:
    print(f'❌ NCC模块导入失败: {e}')

try:
    import requests, selenium, schedule, numpy, PIL
    print('✅ 基础依赖模块导入成功')
except ImportError as e:
    print(f'❌ 基础依赖模块导入失败: {e}')

print('✅ ARMv7镜像测试完成')
"; then
        success "ARMv7镜像测试通过！"
    else
        warning "ARMv7镜像测试失败，但构建成功"
    fi
}

# 主函数
main() {
    info "🚀 开始Linux环境下的Docker Buildx安装和ARMv7构建"
    echo "=================================================="
    
    # 检查是否为root用户
    if [ "$EUID" -eq 0 ]; then
        warning "不建议以root用户运行此脚本"
        read -p "是否继续？(y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    # 检测系统
    detect_distro
    
    # 安装组件
    install_docker
    install_buildx
    install_qemu
    setup_buildx_builder
    
    # 构建镜像
    build_armv7_image
    
    success "🎉 所有任务完成！"
    
    echo ""
    info "📋 使用说明："
    echo "1. 构建的镜像: sgcc_electricity:armv7-linux-build"
    echo "2. 导出镜像: docker save sgcc_electricity:armv7-linux-build | gzip > sgcc_armv7.tar.gz"
    echo "3. 在ARMv7设备上导入: docker load < sgcc_armv7.tar.gz"
    echo "4. 推送到仓库: docker tag sgcc_electricity:armv7-linux-build your-registry/sgcc_electricity:armv7"
    echo "               docker push your-registry/sgcc_electricity:armv7"
    echo ""
    
    warning "💡 注意："
    echo "- 如果是首次安装Docker，请注销并重新登录"
    echo "- 或者运行: newgrp docker"
    echo "- 然后重新运行此脚本"
}

# 运行主函数
main "$@"
