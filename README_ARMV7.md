# SGCC电费查询 - ARMv7架构构建指南

本指南专门针对ARMv7架构设备（如树莓派）的Docker镜像构建和部署。

## 🏗️ 构建要求

### 系统要求
- Docker 19.03.9 或更高版本
- Docker Buildx 支持
- QEMU 多架构支持

### 支持的设备
- 树莓派 2B, 3B, 3B+, 4B（32位系统）
- 其他基于ARMv7架构的单板计算机

## 🚀 快速开始

### 1. 准备构建环境

在x86_64主机上安装多架构支持：

```bash
# 安装QEMU多架构支持
sudo apt-get update
sudo apt-get install qemu qemu-user-static binfmt-support

# 启用Docker buildx
docker buildx create --use

# 设置QEMU支持
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
```

### 2. 构建ARMv7镜像

使用提供的构建脚本：

```bash
# 给构建脚本执行权限
chmod +x build_armv7.sh

# 执行构建
./build_armv7.sh
```

或手动构建：

```bash
docker buildx build \
  --platform=linux/arm/v7 \
  --file=Dockerfile-armv7 \
  --tag=sgcc_electricity:armv7-latest \
  --progress=plain \
  .
```

### 3. 在ARMv7设备上部署

#### 方法一：使用docker-compose（推荐）

1. 将镜像推送到仓库或传输到目标设备
2. 在ARMv7设备上创建环境变量文件：

```bash
# 复制环境变量模板
cp .env.armv7.example .env

# 编辑环境变量
nano .env
```

3. 启动服务：

```bash
# 使用ARMv7专用的compose文件
docker-compose -f docker-compose-armv7.yml up -d
```

#### 方法二：直接运行Docker容器

```bash
docker run -d \
  --name sgcc_electricity_armv7 \
  --platform linux/arm/v7 \
  --network host \
  -v $(pwd):/data \
  -e PHONE_NUMBER='your_phone' \
  -e PASSWORD='your_password' \
  -e HASS_URL='http://homeassistant.local:8123/' \
  -e HASS_TOKEN='your_token' \
  -e TZ='Asia/Shanghai' \
  sgcc_electricity:armv7-latest
```

## 🔧 配置说明

### 必需的环境变量

| 变量名 | 说明 | 示例 |
|--------|------|------|
| `PHONE_NUMBER` | 国网账号手机号 | `13800138000` |
| `PASSWORD` | 国网账号密码 | `your_password` |
| `HASS_URL` | Home Assistant地址 | `http://192.168.1.100:8123/` |
| `HASS_TOKEN` | HA长期访问令牌 | `your_token` |

### 可选的环境变量

| 变量名 | 默认值 | 说明 |
|--------|--------|------|
| `JOB_START_TIME` | `07:00` | 任务执行时间 |
| `RETRY_TIMES_LIMIT` | `5` | 最大重试次数 |
| `LOG_LEVEL` | `INFO` | 日志级别 |
| `DATA_RETENTION_DAYS` | `7` | 数据保留天数 |

## 🛠️ 故障排除

### 常见问题

1. **构建缓慢**
   - ARMv7架构的交叉编译较慢，请耐心等待
   - 建议在网络良好的环境下构建

2. **geckodriver下载失败**
   - 检查网络连接
   - 可能需要配置代理

3. **内存不足**
   - ARMv7设备内存有限，建议为容器设置合适的内存限制
   - 可以在docker-compose文件中调整资源限制

4. **Firefox启动失败**
   - 确保设备有足够的内存
   - 检查显示相关的配置

### 调试命令

```bash
# 查看容器日志
docker logs -f sgcc_electricity_armv7

# 进入容器调试
docker exec -it sgcc_electricity_armv7 /bin/bash

# 检查容器资源使用
docker stats sgcc_electricity_armv7

# 测试模块导入
docker exec sgcc_electricity_armv7 python3 -c "from ncc_matcher import NCCMatcher; print('OK')"
```

## 📊 性能优化

### 针对ARMv7的优化配置

1. **内存优化**
   ```yaml
   deploy:
     resources:
       limits:
         memory: 512M
       reservations:
         memory: 256M
   ```

2. **CPU优化**
   ```bash
   export OMP_NUM_THREADS=2  # 限制OpenMP线程数
   ```

3. **存储优化**
   - 使用SSD存储提高I/O性能
   - 定期清理Docker镜像和容器

## 🔄 更新和维护

### 更新镜像

```bash
# 重新构建镜像
./build_armv7.sh

# 停止旧容器
docker-compose -f docker-compose-armv7.yml down

# 启动新容器
docker-compose -f docker-compose-armv7.yml up -d
```

### 数据备份

```bash
# 备份数据目录
tar -czf sgcc_backup_$(date +%Y%m%d).tar.gz /path/to/data

# 备份数据库（如果启用）
docker exec sgcc_electricity_armv7 sqlite3 /data/homeassistant.db ".backup /data/backup.db"
```

## 📋 版本信息

- ARMv7优化版本: v1.6.8-armv7
- 基础镜像: python:3.12-slim-bookworm
- 支持架构: linux/arm/v7
- Gecko驱动: v0.35.0

## 🤝 贡献

如果您在ARMv7设备上遇到问题或有改进建议，欢迎提交Issue或Pull Request。

## 📝 许可证

本项目遵循原项目的许可证。
