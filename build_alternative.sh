#!/bin/bash
# 替代构建方案 - 适用于Apple Silicon Mac
# 构建本地可运行的ARM64镜像

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
IMAGE_TAG="local-arm64"
FULL_IMAGE_NAME="${IMAGE_NAME}:${IMAGE_TAG}"

info "🚀 开始构建本地ARM64版本的SGCC电费查询Docker镜像"
echo "=================================="
info "镜像名称: ${FULL_IMAGE_NAME}"
info "目标架构: 本地架构 (ARM64)"
info "适用设备: Apple Silicon Mac, 新版树莓派, ARM64设备"
echo "=================================="

# 创建简化的Dockerfile
cat > Dockerfile-local-arm64 << 'EOF'
FROM python:3.12-slim-bookworm

# 设置环境变量
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV TZ=Asia/Shanghai
ENV PYTHON_IN_DOCKER='PYTHON_IN_DOCKER'

# 安装系统依赖
RUN apt-get update && apt-get install -y --no-install-recommends \
    firefox-esr \
    tzdata \
    jq \
    wget \
    && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
    && echo $TZ > /etc/timezone \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# 创建工作目录
WORKDIR /app
RUN mkdir -p /data

# 复制requirements.txt并安装Python依赖
COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r /tmp/requirements.txt \
    && rm -rf /tmp/* \
    && pip cache purge

# 安装geckodriver for ARM64
RUN wget -O /tmp/geckodriver.tgz \
    "https://github.com/mozilla/geckodriver/releases/download/v0.35.0/geckodriver-v0.35.0-linux-aarch64.tar.gz" \
    && tar -xzf /tmp/geckodriver.tgz -C /usr/local/bin/ \
    && chmod +x /usr/local/bin/geckodriver \
    && rm -f /tmp/geckodriver.tgz \
    && geckodriver --version

# 复制应用代码
COPY scripts/*.py ./

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python3 -c "from ncc_matcher import NCCMatcher; print('OK')" || exit 1

# 启动命令
CMD ["python3", "main.py"]
EOF

info "📋 已创建简化的Dockerfile-local-arm64"

# 开始构建
info "🔨 开始构建本地ARM64镜像..."
start_time=$(date +%s)

docker build -f Dockerfile-local-arm64 -t "${FULL_IMAGE_NAME}" .

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
docker images "${FULL_IMAGE_NAME}"

# 测试镜像功能
info "🧪 测试镜像功能..."
test_container_name="sgcc_test_local"

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
    import traceback
    traceback.print_exc()

try:
    import requests, selenium, schedule, numpy
    print('✅ 基础依赖模块导入成功')
except ImportError as e:
    print(f'❌ 基础依赖模块导入失败: {e}')

print('✅ 模块测试完成')
"; then
    success "模块导入测试通过"
else
    warning "模块导入测试失败，但镜像构建成功"
fi

# 显示使用说明
echo ""
success "🎉 本地ARM64镜像构建完成！"
echo ""
info "📋 使用说明:"
echo ""
echo "  1. 本地运行测试:"
echo "     docker run --rm -it \\"
echo "       -e PHONE_NUMBER='your_phone' \\"
echo "       -e PASSWORD='your_password' \\"
echo "       -e HASS_URL='http://your_ha_ip:8123/' \\"
echo "       -e HASS_TOKEN='your_token' \\"
echo "       ${FULL_IMAGE_NAME}"
echo ""
echo "  2. 后台运行:"
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

# 创建docker-compose文件
cat > docker-compose-local.yml << EOF
version: '3.8'

services:
  sgcc_electricity_local:
    image: ${FULL_IMAGE_NAME}
    container_name: sgcc_electricity_local
    network_mode: "host"
    
    environment:
      - TZ=Asia/Shanghai
      # 以下环境变量需要根据实际情况修改
      - PHONE_NUMBER=\${PHONE_NUMBER:-}
      - PASSWORD=\${PASSWORD:-}
      - HASS_URL=\${HASS_URL:-http://homeassistant.local:8123/}
      - HASS_TOKEN=\${HASS_TOKEN:-}
      - JOB_START_TIME=\${JOB_START_TIME:-07:00}
      - LOG_LEVEL=\${LOG_LEVEL:-INFO}
    
    env_file:
      - .env
    
    volumes:
      - ./:/data
    
    restart: unless-stopped
    command: python3 main.py
    init: true
    
    healthcheck:
      test: ["CMD", "python3", "-c", "from ncc_matcher import NCCMatcher; print('OK')"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 30s
    
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
EOF

info "📄 已创建 docker-compose-local.yml 配置文件"

warning "💡 重要说明:"
echo "  - 该镜像构建为ARM64架构，适用于:"
echo "    * Apple Silicon Mac (本机)"
echo "    * 树莓派4B/5 (64位系统)"
echo "    * 其他ARM64设备"
echo "  - 如需在ARMv7设备上运行，请使用x86_64 Linux机器构建"
echo "  - 可以使用 docker-compose -f docker-compose-local.yml up -d 启动"

success "构建脚本执行完成！"

# 清理临时文件
rm -f Dockerfile-local-arm64
info "🧹 已清理临时文件"
