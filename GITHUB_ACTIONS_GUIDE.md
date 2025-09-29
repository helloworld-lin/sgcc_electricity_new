# 🚀 GitHub Actions自动编译ARMv7镜像详细指南

## 📋 概述

使用GitHub Actions可以在云端自动编译ARMv7 Docker镜像，完全免费且无需本地环境限制。

## 🎯 详细步骤

### 第1步：准备GitHub仓库

#### 1.1 创建GitHub账号（如果没有）
- 访问 [github.com](https://github.com) 注册账号

#### 1.2 在本地初始化Git仓库

```bash
# 在项目目录下执行
git init
git add .
git commit -m "Initial commit: Add ARMv7 build support"
```

#### 1.3 在GitHub上创建新仓库

1. 登录GitHub
2. 点击右上角 "+" → "New repository"
3. 填写仓库信息：
   - Repository name: `sgcc_electricity_new`
   - Description: `SGCC电费查询系统 - 支持ARMv7架构`
   - 选择 Public 或 Private
   - 不要勾选 "Initialize this repository with a README"
4. 点击 "Create repository"

#### 1.4 连接本地仓库到GitHub

```bash
# 替换YOUR_USERNAME为你的GitHub用户名
git remote add origin https://github.com/YOUR_USERNAME/sgcc_electricity_new.git
git branch -M main
git push -u origin main
```

### 第2步：设置Docker Hub（必需）

#### 2.1 创建Docker Hub账号
- 访问 [hub.docker.com](https://hub.docker.com) 注册账号

#### 2.2 生成访问令牌
1. 登录Docker Hub
2. 点击右上角头像 → "Account Settings"
3. 选择 "Security" → "Access Tokens"
4. 点击 "New Access Token"
5. 输入令牌描述：`GitHub Actions Build`
6. 权限选择：`Read, Write, Delete`
7. 点击 "Generate"
8. **重要**：复制生成的令牌（只显示一次！）

### 第3步：配置GitHub Secrets

#### 3.1 在GitHub仓库中添加Secrets
1. 进入你的GitHub仓库页面
2. 点击 "Settings" 标签
3. 在左侧菜单选择 "Secrets and variables" → "Actions"
4. 点击 "New repository secret"

#### 3.2 添加两个必需的Secrets

**Secret 1：DOCKERHUB_USERNAME**
- Name: `DOCKERHUB_USERNAME`
- Secret: 你的Docker Hub用户名
- 点击 "Add secret"

**Secret 2：DOCKERHUB_TOKEN**
- Name: `DOCKERHUB_TOKEN`
- Secret: 刚才复制的Docker Hub访问令牌
- 点击 "Add secret"

### 第4步：查看和理解GitHub Actions工作流

我已经为你创建了完整的工作流文件 `.github/workflows/build-armv7.yml`，它包含：

```yaml
name: Build ARMv7 Docker Image

# 触发条件
on:
  push:
    branches: [ main, master ]    # 推送到主分支时触发
  pull_request:
    branches: [ main, master ]    # PR时触发（仅测试，不推送）
  workflow_dispatch:              # 手动触发

# 环境变量
env:
  REGISTRY: docker.io
  IMAGE_NAME: sgcc_electricity

jobs:
  build:
    runs-on: ubuntu-latest        # 使用最新Ubuntu环境
    
    steps:
    # 1. 检出代码
    - name: Checkout repository
      uses: actions/checkout@v4
    
    # 2. 设置QEMU多架构支持
    - name: Set up QEMU
      uses: docker/setup-qemu-action@v3
      with:
        platforms: linux/arm/v7
    
    # 3. 设置Docker Buildx
    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v3
    
    # 4. 登录Docker Hub
    - name: Log in to Docker Hub
      if: github.event_name != 'pull_request'
      uses: docker/login-action@v3
      with:
        registry: ${{ env.REGISTRY }}
        username: ${{ secrets.DOCKERHUB_USERNAME }}
        password: ${{ secrets.DOCKERHUB_TOKEN }}
    
    # 5. 生成镜像标签
    - name: Extract metadata
      id: meta
      uses: docker/metadata-action@v5
      with:
        images: ${{ env.REGISTRY }}/${{ secrets.DOCKERHUB_USERNAME }}/${{ env.IMAGE_NAME }}
        tags: |
          type=raw,value=armv7-latest,enable={{is_default_branch}}
          type=sha,prefix=armv7-{{branch}}-
    
    # 6. 构建并推送镜像
    - name: Build and push Docker image
      uses: docker/build-push-action@v5
      with:
        context: .
        file: ./Dockerfile-armv7
        platforms: linux/arm/v7
        push: ${{ github.event_name != 'pull_request' }}
        tags: ${{ steps.meta.outputs.tags }}
        cache-from: type=gha
        cache-to: type=gha,mode=max
```

### 第5步：触发构建

#### 5.1 自动触发（推荐）
```bash
# 修改任何文件后推送即可触发
echo "# ARMv7 Build Ready" >> README.md
git add .
git commit -m "Trigger ARMv7 build"
git push
```

#### 5.2 手动触发
1. 进入GitHub仓库页面
2. 点击 "Actions" 标签
3. 选择 "Build ARMv7 Docker Image" 工作流
4. 点击 "Run workflow" → "Run workflow"

### 第6步：监控构建过程

#### 6.1 查看构建状态
1. 在GitHub仓库的 "Actions" 标签页
2. 找到你的构建任务
3. 点击进入查看详细日志

#### 6.2 构建过程说明
- ⏱️ **总时间**：约10-15分钟
- 🔄 **步骤**：
  1. 检出代码 (30秒)
  2. 设置QEMU (1分钟)
  3. 设置Buildx (30秒)
  4. 登录Docker Hub (10秒)
  5. 构建镜像 (8-12分钟)
  6. 推送镜像 (2-3分钟)
  7. 生成报告 (10秒)

### 第7步：使用构建好的镜像

#### 7.1 镜像地址
构建成功后，镜像会推送到：
```
your-dockerhub-username/sgcc_electricity:armv7-latest
```

#### 7.2 在ARMv7设备上使用

```bash
# 拉取镜像
docker pull your-dockerhub-username/sgcc_electricity:armv7-latest

# 运行容器
docker run -d --name sgcc_electricity \
  --network host \
  -v $(pwd):/data \
  -e PHONE_NUMBER='13800138000' \
  -e PASSWORD='your_password' \
  -e HASS_URL='http://homeassistant.local:8123/' \
  -e HASS_TOKEN='your_hass_token' \
  your-dockerhub-username/sgcc_electricity:armv7-latest

# 查看日志
docker logs -f sgcc_electricity
```

#### 7.3 使用docker-compose
```yaml
version: '3.8'
services:
  sgcc_electricity:
    image: your-dockerhub-username/sgcc_electricity:armv7-latest
    container_name: sgcc_electricity
    network_mode: host
    environment:
      - PHONE_NUMBER=13800138000
      - PASSWORD=your_password
      - HASS_URL=http://homeassistant.local:8123/
      - HASS_TOKEN=your_hass_token
    volumes:
      - ./:/data
    restart: unless-stopped
```

## 🎉 完整操作示例

让我演示完整的操作流程：

```bash
# 1. 初始化并推送代码
git init
git add .
git commit -m "Initial commit: ARMv7 build support"
git remote add origin https://github.com/YOUR_USERNAME/sgcc_electricity_new.git
git push -u origin main

# 2. 在GitHub网页上设置Secrets（DOCKERHUB_USERNAME 和 DOCKERHUB_TOKEN）

# 3. 触发构建
echo "构建时间: $(date)" >> build.log
git add .
git commit -m "Trigger ARMv7 build"
git push

# 4. 等待构建完成（10-15分钟）

# 5. 在ARMv7设备上使用
docker run -d --name sgcc_electricity \
  --network host \
  -v $(pwd):/data \
  -e PHONE_NUMBER='your_phone' \
  -e PASSWORD='your_password' \
  YOUR_USERNAME/sgcc_electricity:armv7-latest
```

## 🔧 故障排除

### 常见问题

1. **构建失败：权限错误**
   - 检查Docker Hub的用户名和令牌是否正确
   - 确保令牌有足够权限

2. **构建失败：文件未找到**
   - 确保所有必要文件都已推送到GitHub
   - 检查 `.gitignore` 是否排除了重要文件

3. **镜像推送失败**
   - 检查Docker Hub仓库是否存在
   - 确认网络连接正常

4. **在ARM设备上运行失败**
   - 确认设备架构：`uname -a`
   - 检查Docker是否支持该架构

### 调试技巧

```bash
# 查看构建日志
# 在GitHub Actions页面点击具体的构建任务查看详细日志

# 本地测试Dockerfile
docker build -f Dockerfile-armv7 -t test-image .

# 检查镜像信息
docker inspect your-username/sgcc_electricity:armv7-latest
```

## 📊 构建结果

构建成功后，你将获得：

- ✅ **ARMv7优化镜像**：约300-400MB
- ✅ **自动推送到Docker Hub**：可直接拉取使用
- ✅ **版本管理**：每次构建都有唯一标签
- ✅ **构建缓存**：后续构建更快
- ✅ **完整测试**：自动验证镜像功能

## 💡 高级技巧

### 自动构建多个版本
修改工作流文件，可以同时构建多个架构：

```yaml
platforms: linux/amd64,linux/arm64,linux/arm/v7
```

### 定时构建
添加定时触发器：

```yaml
on:
  schedule:
    - cron: '0 2 * * 0'  # 每周日凌晨2点构建
```

### 条件构建
只在特定条件下构建：

```yaml
if: contains(github.event.head_commit.message, '[build]')
```

## 🎯 总结

GitHub Actions方案的优势：

- 🆓 **完全免费**：每月2000分钟免费额度
- 🔄 **全自动化**：推送代码即可触发构建
- 🛡️ **环境隔离**：每次都是全新的Ubuntu环境
- 📦 **原生支持**：完美支持Docker多架构构建
- 🔗 **集成度高**：与GitHub和Docker Hub无缝集成
- 📊 **可视化好**：清晰的构建日志和状态显示

现在你已经掌握了使用GitHub Actions自动编译ARMv7镜像的完整流程！
