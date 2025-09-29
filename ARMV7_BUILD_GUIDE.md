# ARMv7架构镜像构建完整指南

## 🎯 项目完成状态

✅ **已完成的优化：**

1. **Dockerfile-armv7优化**
   - 明确指定`--platform=linux/arm/v7`确保架构兼容性
   - 优化基础镜像为`python:3.12-slim-bookworm`
   - 配置国内镜像源提高下载速度
   - 优化geckodriver下载为armv7专用版本
   - 修正健康检查模块导入路径

2. **专用构建脚本**
   - `build_armv7.sh` - 全自动化构建脚本
   - 包含环境检查、多架构支持设置、构建和测试
   - 带有彩色输出和详细的进度信息

3. **部署配置**
   - `docker-compose-armv7.yml` - ARMv7专用compose配置
   - 针对ARM设备的资源限制优化
   - 完整的环境变量配置

4. **文档和指南**
   - `README_ARMV7.md` - 详细的使用说明
   - 包含故障排除和性能优化建议

## 🚀 使用步骤

### 1. 启动Docker服务

```bash
# macOS/Windows
# 启动Docker Desktop应用程序

# Linux
sudo systemctl start docker
sudo systemctl enable docker
```

### 2. 设置多架构支持

```bash
# 安装QEMU（仅Linux需要）
sudo apt-get update
sudo apt-get install qemu qemu-user-static binfmt-support

# 设置多架构支持
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes

# 创建buildx构建器
docker buildx create --use --name armv7-builder --platform linux/arm/v7
```

### 3. 执行构建

```bash
# 方法一：使用自动化脚本（推荐）
chmod +x build_armv7.sh
./build_armv7.sh

# 方法二：手动构建
docker buildx build \
  --platform=linux/arm/v7 \
  --file=Dockerfile-armv7 \
  --tag=sgcc_electricity:armv7-latest \
  --progress=plain \
  .
```

### 4. 推送到仓库（可选）

```bash
# 推送到Docker Hub
docker buildx build \
  --platform=linux/arm/v7 \
  --file=Dockerfile-armv7 \
  --tag=your-username/sgcc_electricity:armv7-latest \
  --push \
  .
```

### 5. 在ARMv7设备上部署

```bash
# 使用docker-compose（推荐）
cp .env.example .env  # 编辑环境变量
docker-compose -f docker-compose-armv7.yml up -d

# 或直接运行
docker run -d \
  --name sgcc_electricity \
  --platform linux/arm/v7 \
  --network host \
  -v $(pwd):/data \
  -e PHONE_NUMBER='your_phone' \
  -e PASSWORD='your_password' \
  -e HASS_URL='http://homeassistant.local:8123/' \
  -e HASS_TOKEN='your_token' \
  sgcc_electricity:armv7-latest
```

## 🔧 关键优化点

### Dockerfile优化
- 使用国内镜像源加速包下载
- 针对armv7架构选择正确的geckodriver版本
- 优化了重试机制和超时设置
- 修正了模块导入路径

### 构建脚本特性
- 自动检测和设置构建环境
- 智能错误处理和回滚
- 详细的进度显示和日志输出
- 自动化测试验证

### 部署优化
- 针对ARM设备的资源限制
- 完善的健康检查配置
- 日志轮转和存储优化

## ⚠️ 注意事项

1. **构建时间**：ARMv7交叉编译需要较长时间，请耐心等待
2. **内存要求**：建议构建机器至少有4GB内存
3. **网络连接**：需要稳定的网络连接下载依赖
4. **Docker版本**：确保Docker版本≥19.03.9以支持buildx

## 🛠️ 故障排除

### 常见问题及解决方案

1. **Docker daemon未运行**
   ```bash
   # 启动Docker服务
   sudo systemctl start docker  # Linux
   # 或启动Docker Desktop    # macOS/Windows
   ```

2. **buildx不可用**
   ```bash
   # 更新Docker到最新版本
   # 或手动安装buildx插件
   ```

3. **QEMU支持缺失**
   ```bash
   # 重新设置QEMU支持
   docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
   ```

4. **构建内存不足**
   ```bash
   # 增加Docker内存限制
   # 或在构建机器上释放内存
   ```

## 📊 文件清单

创建/修改的文件：
- ✅ `Dockerfile-armv7` - 优化的ARMv7 Dockerfile
- ✅ `build_armv7.sh` - 自动化构建脚本
- ✅ `docker-compose-armv7.yml` - ARMv7专用compose配置
- ✅ `README_ARMV7.md` - 详细使用说明
- ✅ `ARMV7_BUILD_GUIDE.md` - 本构建指南

## 🎉 构建成功后

构建完成后，你将获得：
- 一个优化的ARMv7架构Docker镜像
- 完整的部署配置文件
- 详细的使用和维护文档
- 自动化的构建和测试流程

现在你可以：
1. 启动Docker服务
2. 运行 `./build_armv7.sh` 开始构建
3. 等待构建完成
4. 在ARMv7设备上部署和运行

**构建预期时间：15-30分钟（取决于网络和硬件性能）**
