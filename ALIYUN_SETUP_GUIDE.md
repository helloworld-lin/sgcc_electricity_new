# 🚀 阿里云容器镜像服务配置指南

## 📋 概述

由于Docker Hub在国内访问较慢，我们已经配置了阿里云容器镜像服务作为国内镜像源。现在需要完成阿里云的配置。

## 🔧 第1步：创建阿里云镜像仓库

### 1.1 登录阿里云控制台
- 访问：https://cr.console.aliyun.com/
- 登录你的阿里云账号（没有的话需要先注册）

### 1.2 选择地域
建议选择：**华东1（杭州）**
- 对应镜像地址：`registry.cn-hangzhou.aliyuncs.com`

### 1.3 创建命名空间
1. 点击左侧菜单 "命名空间"
2. 点击 "创建命名空间"
3. **命名空间名称**：`helloworld-lin`（与你的GitHub用户名保持一致）
4. 点击 "确定"

### 1.4 创建镜像仓库
1. 点击左侧菜单 "镜像仓库"
2. 点击 "创建镜像仓库"
3. 填写仓库信息：
   - **命名空间**：选择刚创建的 `helloworld-lin`
   - **仓库名称**：`sgcc_electricity`
   - **仓库类型**：公开（推荐）或私有
   - **摘要**：SGCC电费查询系统ARMv7镜像
4. 点击 "下一步"
5. **代码源**：选择 "本地仓库"
6. 点击 "创建镜像仓库"

## 🔐 第2步：获取阿里云访问凭证

### 2.1 设置Registry登录密码
1. 在阿里云控制台，点击右上角头像
2. 选择 "AccessKey管理"
3. 建议创建RAM用户专门用于容器镜像服务
4. 或者使用 "容器镜像服务" → "访问凭证" 设置独立密码

### 2.2 记录访问信息
- **Registry地址**：`registry.cn-hangzhou.aliyuncs.com`
- **命名空间**：`helloworld-lin`
- **用户名**：你的阿里云账号或RAM用户名
- **密码**：设置的Registry密码

## ⚙️ 第3步：配置GitHub Secrets

在GitHub仓库中添加阿里云相关的Secrets：

1. **访问GitHub仓库设置**：
   - https://github.com/helloworld-lin/sgcc_electricity_new/settings/secrets/actions

2. **添加以下Secrets**：

   **ALIYUN_USERNAME**：
   - Name: `ALIYUN_USERNAME`
   - Secret: 你的阿里云账号邮箱或RAM用户名

   **ALIYUN_PASSWORD**：
   - Name: `ALIYUN_PASSWORD`
   - Secret: 容器镜像服务密码

   **ALIYUN_NAMESPACE**：
   - Name: `ALIYUN_NAMESPACE`
   - Secret: `helloworld-lin`

## 🚀 第4步：触发构建

配置完成后，推送代码触发构建：

```bash
echo "配置阿里云镜像源: $(date)" >> README.md
git add .
git commit -m "🐳 配置阿里云容器镜像服务支持"
git push
```

## 📦 第5步：使用阿里云镜像

### 5.1 Docker命令
```bash
# 拉取镜像（国内速度更快）
docker pull registry.cn-hangzhou.aliyuncs.com/helloworld-lin/sgcc_electricity:armv7-latest

# 运行容器
docker run -d \
  --name sgcc_electricity \
  --network host \
  --restart unless-stopped \
  -v $(pwd)/data:/data \
  -e PHONE_NUMBER='13800138000' \
  -e PASSWORD='your_password' \
  -e HASS_URL='http://192.168.1.100:8123/' \
  -e HASS_TOKEN='your_hass_token' \
  registry.cn-hangzhou.aliyuncs.com/helloworld-lin/sgcc_electricity:armv7-latest
```

### 5.2 Docker Compose
使用更新后的 `docker-compose-armv7.yml`：

```bash
# 启动服务
docker-compose -f docker-compose-armv7.yml up -d

# 查看日志
docker-compose -f docker-compose-armv7.yml logs -f
```

## 🔄 镜像同步策略

现在GitHub Actions会同时推送到两个镜像源：

1. **阿里云镜像**（国内推荐）：
   - `registry.cn-hangzhou.aliyuncs.com/helloworld-lin/sgcc_electricity:armv7-latest`

2. **Docker Hub镜像**（国外）：
   - `helloworld-lin/sgcc_electricity:armv7-latest`

## 🌐 其他地域的阿里云镜像

如果你在其他地区，可以选择就近的Registry：

- **华北1（青岛）**：`registry.cn-qingdao.aliyuncs.com`
- **华北2（北京）**：`registry.cn-beijing.aliyuncs.com`
- **华南1（深圳）**：`registry.cn-shenzhen.aliyuncs.com`
- **华东2（上海）**：`registry.cn-shanghai.aliyuncs.com`

## 💡 优势

使用阿里云镜像源的优势：

- ✅ **下载速度快**：国内CDN加速
- ✅ **稳定性好**：避免Docker Hub访问问题
- ✅ **双重备份**：同时维护两个镜像源
- ✅ **自动同步**：GitHub Actions自动推送

---

配置完成后，你就可以享受快速的容器镜像拉取体验了！🚀
