# 🏠 阿里云个人版容器镜像服务配置

## ✅ 登录测试成功！

本地测试登录成功：
```
Login Succeeded
```

## 📝 GitHub Secrets 配置

请在GitHub仓库中设置以下Secrets：

### 必需的Secrets

1. **ALIYUN_USERNAME**
   ```
   aliyun0809566164
   ```

2. **ALIYUN_PASSWORD**
   ```
   1103194lxz
   ```

### 设置步骤

1. 访问GitHub仓库：https://github.com/helloworld-lin/sgcc_electricity_new
2. 点击 Settings → Secrets and variables → Actions
3. 点击 "New repository secret"
4. 添加以下两个secrets：

   **Secret 1:**
   - Name: `ALIYUN_USERNAME`
   - Value: `aliyun0809566164`

   **Secret 2:**
   - Name: `ALIYUN_PASSWORD`
   - Value: `1103194lxz`

## 🎯 镜像地址

配置完成后，将生成以下镜像：

**阿里云个人版（国内推荐）**：
```bash
crpi-s1ugew53omsoe998.cn-hangzhou.personal.cr.aliyuncs.com/helloworld-lin/sgcc_electricity:armv7-latest
```

**Docker Hub（国外）**：
```bash
helloworld-lin/sgcc_electricity:armv7-latest
```

## 🚀 使用方法

### 拉取镜像
```bash
# 阿里云个人版（国内推荐）
docker pull crpi-s1ugew53omsoe998.cn-hangzhou.personal.cr.aliyuncs.com/helloworld-lin/sgcc_electricity:armv7-latest

# Docker Hub（国外）
docker pull helloworld-lin/sgcc_electricity:armv7-latest
```

### 运行容器
```bash
docker run -d --name sgcc_electricity \
  --network host \
  -v $(pwd):/data \
  -e PHONE_NUMBER='your_phone' \
  -e PASSWORD='your_password' \
  crpi-s1ugew53omsoe998.cn-hangzhou.personal.cr.aliyuncs.com/helloworld-lin/sgcc_electricity:armv7-latest
```

## 📋 下一步

1. ✅ 本地登录测试成功
2. 🔄 设置GitHub Secrets（你需要手动完成）
3. 🚀 触发构建测试

完成GitHub Secrets设置后，告诉我，我将触发构建测试！
