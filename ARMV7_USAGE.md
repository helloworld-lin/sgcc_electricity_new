# ARMv7 Docker 部署指南

## 🎯 架构说明

本项目采用**纯环境镜像 + 本地代码挂载**模式：

- **Docker 镜像**：只包含运行环境（Python、依赖包、geckodriver），不包含代码
- **本地代码**：通过 volume 挂载到容器，方便开发和调试
- **权限设置**：容器以 root 权限运行，避免所有权限问题

## 📦 镜像内容

- Python 3.12 + 系统依赖
- Python 包：numpy, Pillow, selenium, requests, schedule, sympy 等
- Geckodriver v0.34.0 (ARMv7 linux32 架构)
- Firefox ESR

## 🚀 使用方法

### 1. 克隆代码到 ARMv7 设备

```bash
git clone https://github.com/helloworld-lin/sgcc_electricity_new.git
cd sgcc_electricity_new
```

### 2. 配置环境变量

```bash
cp example.env .env
vim .env  # 填写您的配置
```

### 3. 拉取最新镜像

```bash
# 国内推荐使用阿里云镜像
docker pull crpi-s1ugew53omsoe998.cn-hangzhou.personal.cr.aliyuncs.com/helloworld-lin/sgcc_electricity:armv7-latest

# 或使用 Docker Hub（国外）
docker pull helloworld-lin/sgcc_electricity:armv7-latest
```

### 4. 启动容器

```bash
docker-compose -f docker-compose-armv7.yml up -d
```

### 5. 查看日志

```bash
docker-compose -f docker-compose-armv7.yml logs -f
```

## 📂 目录结构

```
sgcc_electricity_new/
├── scripts/              # 代码目录（挂载到容器）
│   ├── main.py
│   ├── data_fetcher.py
│   └── ...
├── data/                 # 数据存储目录
├── .env                  # 环境变量配置
├── docker-compose-armv7.yml  # Docker Compose 配置
└── Dockerfile-armv7      # Dockerfile（用于构建镜像）
```

## 🔄 更新代码

由于代码通过 volume 挂载，直接在本地修改代码即可：

```bash
# 1. 更新代码
git pull

# 2. 重启容器使修改生效
docker-compose -f docker-compose-armv7.yml restart
```

## 🔧 重新构建镜像

如果修改了 Dockerfile-armv7 或 requirements.txt，需要重新构建镜像：

### 方法1：通过 GitHub Actions（推荐）

1. 提交修改到 GitHub
2. GitHub Actions 自动构建并推送到 Docker Hub 和阿里云
3. 在 ARMv7 设备上拉取新镜像：
   ```bash
   docker-compose -f docker-compose-armv7.yml pull
   docker-compose -f docker-compose-armv7.yml up -d
   ```

### 方法2：本地构建（仅限 ARMv7 设备）

```bash
docker build -f Dockerfile-armv7 -t my-sgcc:armv7 .
# 修改 docker-compose-armv7.yml 中的 image 为 my-sgcc:armv7
docker-compose -f docker-compose-armv7.yml up -d
```

## 🐛 故障排查

### 问题1：权限错误

**现象**：`Permission denied: '/data/errors'`

**解决**：容器已配置为 root 权限运行，不应再出现此问题

### 问题2：geckodriver 架构不匹配

**现象**：`[Errno 8] Exec format error: '/usr/local/bin/geckodriver'`

**解决**：确保使用最新镜像，镜像已包含正确的 ARMv7 版本 geckodriver

### 问题3：无法连接 Home Assistant

**现象**：`Connection refused`

**解决**：
- 检查 `HASS_URL` 配置
- 容器使用 `network_mode: host`，应使用 `http://localhost:8123/`

### 问题4：容器无法启动

**解决**：
```bash
# 查看详细日志
docker-compose -f docker-compose-armv7.yml logs

# 检查容器状态
docker ps -a

# 重新创建容器
docker-compose -f docker-compose-armv7.yml down
docker-compose -f docker-compose-armv7.yml up -d
```

## 📊 监控构建状态

访问 GitHub Actions 查看镜像构建进度：
https://github.com/helloworld-lin/sgcc_electricity_new/actions

## ⚙️ 高级配置

### 修改资源限制

编辑 `docker-compose-armv7.yml`：

```yaml
deploy:
  resources:
    limits:
      memory: 512M  # 根据设备内存调整
      cpus: '1.0'
```

### 修改日志设置

```yaml
logging:
  driver: "json-file"
  options:
    max-size: "10m"  # 单个日志文件大小
    max-file: "3"    # 保留日志文件数量
```

## 🎉 完成

现在您的 SGCC 电力查询服务应该已经在 ARMv7 设备上正常运行了！
