# 🐧 Linux环境下ARMv7镜像构建指南

## 🎯 概述

本指南帮助你在Linux环境下安装Docker Buildx并成功构建ARMv7架构的Docker镜像。

## 📋 前置条件

- Linux系统（Ubuntu、CentOS、Debian等）
- 具有sudo权限的用户账号
- 网络连接

## 🚀 快速开始

### 方案1：全自动安装（从零开始）

如果你的Linux系统还没有Docker，使用完整安装脚本：

```bash
# 传输所有文件到Linux机器
scp -r /Users/wendy/workspace/sgcc_electricity_new user@linux-server:/path/to/

# 登录Linux机器
ssh user@linux-server
cd /path/to/sgcc_electricity_new

# 运行完整安装脚本
chmod +x setup_linux_buildx.sh
./setup_linux_buildx.sh
```

### 方案2：快速设置（已有Docker）

如果Linux系统已安装Docker，使用快速设置脚本：

```bash
# 在Linux机器上
./quick_buildx_setup.sh
```

## 🔧 手动安装步骤

### 1. 安装Docker Buildx

```bash
# 获取最新版本
BUILDX_VERSION=$(curl -s https://api.github.com/repos/docker/buildx/releases/latest | grep tag_name | cut -d '"' -f 4)

# 下载并安装
mkdir -p ~/.docker/cli-plugins
curl -L "https://github.com/docker/buildx/releases/download/${BUILDX_VERSION}/buildx-${BUILDX_VERSION}.linux-amd64" \
    -o ~/.docker/cli-plugins/docker-buildx
chmod +x ~/.docker/cli-plugins/docker-buildx

# 验证安装
docker buildx version
```

### 2. 安装QEMU多架构支持

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y qemu qemu-user-static binfmt-support

# CentOS/RHEL/Fedora
sudo yum install -y qemu-user-static
# 或者
sudo dnf install -y qemu-user-static

# 注册QEMU解释器
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
```

### 3. 创建Buildx构建器

```bash
# 创建支持ARMv7的构建器
docker buildx create --name armv7-builder --platform linux/arm/v7 --use

# 启动构建器
docker buildx inspect armv7-builder --bootstrap

# 查看构建器状态
docker buildx ls
```

### 4. 构建ARMv7镜像

```bash
# 构建镜像
docker buildx build \
    --platform linux/arm/v7 \
    --file Dockerfile-armv7 \
    --tag sgcc_electricity:armv7-latest \
    --load \
    --progress=plain \
    .
```

## 📊 验证构建结果

### 检查镜像信息

```bash
# 查看镜像
docker images sgcc_electricity:armv7-latest

# 检查镜像架构
docker inspect sgcc_electricity:armv7-latest | grep Architecture
```

### 测试镜像功能

```bash
# 基础测试
docker run --rm sgcc_electricity:armv7-latest python3 -c "
import sys
print(f'Python版本: {sys.version}')
print(f'架构: {sys.platform}')

# 测试关键模块
try:
    from ncc_matcher import NCCMatcher
    print('✅ NCC模块可用')
except ImportError as e:
    print(f'❌ NCC模块错误: {e}')

try:
    import requests, selenium, schedule
    print('✅ 基础依赖可用')
except ImportError as e:
    print(f'❌ 依赖错误: {e}')
"
```

## 📤 导出和分发镜像

### 保存镜像到文件

```bash
# 导出镜像
docker save sgcc_electricity:armv7-latest | gzip > sgcc_armv7.tar.gz

# 检查文件大小
ls -lh sgcc_armv7.tar.gz
```

### 在ARMv7设备上导入

```bash
# 传输到目标设备
scp sgcc_armv7.tar.gz user@armv7-device:/path/to/

# 在ARMv7设备上导入
docker load < sgcc_armv7.tar.gz

# 运行容器
docker run -d --name sgcc_electricity \
    --network host \
    -v $(pwd):/data \
    -e PHONE_NUMBER='your_phone' \
    -e PASSWORD='your_password' \
    -e HASS_URL='http://homeassistant.local:8123/' \
    -e HASS_TOKEN='your_token' \
    sgcc_electricity:armv7-latest
```

### 推送到Docker Hub

```bash
# 登录Docker Hub
docker login

# 标记镜像
docker tag sgcc_electricity:armv7-latest your-username/sgcc_electricity:armv7

# 推送镜像
docker push your-username/sgcc_electricity:armv7
```

## 🛠️ 故障排除

### 常见问题

1. **权限错误**
   ```bash
   # 将用户添加到docker组
   sudo usermod -aG docker $USER
   # 重新登录或运行
   newgrp docker
   ```

2. **QEMU注册失败**
   ```bash
   # 手动注册
   sudo docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
   ```

3. **构建器创建失败**
   ```bash
   # 删除现有构建器
   docker buildx rm armv7-builder
   # 重新创建
   docker buildx create --name armv7-builder --platform linux/arm/v7 --use
   ```

4. **网络问题**
   ```bash
   # 使用国内镜像源（已在Dockerfile中配置）
   # 或设置代理
   export HTTP_PROXY=http://proxy:port
   export HTTPS_PROXY=http://proxy:port
   ```

### 调试命令

```bash
# 查看构建器详情
docker buildx inspect

# 查看支持的平台
docker buildx inspect --bootstrap | grep Platforms

# 检查QEMU状态
ls /proc/sys/fs/binfmt_misc/

# 测试交叉编译
docker run --rm --platform linux/arm/v7 alpine uname -a
```

## 📈 性能优化

### 构建加速

```bash
# 使用构建缓存
docker buildx build \
    --platform linux/arm/v7 \
    --file Dockerfile-armv7 \
    --tag sgcc_electricity:armv7-latest \
    --cache-from type=local,src=/tmp/.buildx-cache \
    --cache-to type=local,dest=/tmp/.buildx-cache \
    --load \
    .
```

### 多平台同时构建

```bash
# 同时构建多个架构
docker buildx build \
    --platform linux/amd64,linux/arm64,linux/arm/v7 \
    --file Dockerfile-armv7 \
    --tag sgcc_electricity:multi-arch \
    --push \
    .
```

## ✅ 成功标志

构建成功后，你应该看到：

- ✅ Docker Buildx版本信息
- ✅ QEMU多架构支持已注册
- ✅ ARMv7构建器创建成功
- ✅ 镜像构建完成（约300-400MB）
- ✅ 基础功能测试通过

## 🎉 完成

现在你已经成功在Linux环境下构建了ARMv7架构的Docker镜像！这个镜像可以在树莓派等ARMv7设备上完美运行。
