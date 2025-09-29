# 🚀 ARMv7镜像构建 - 快速设置指南

## 📋 当前状况

由于Apple Silicon的技术限制，无法直接在你的Mac上构建ARMv7镜像。但是，我已经为你准备了完整的GitHub Actions自动构建解决方案！

## ✅ 已准备就绪的文件

- ✅ `Dockerfile-armv7` - 优化的ARMv7 Dockerfile
- ✅ `build_armv7.sh` - 构建脚本（在Linux环境下使用）
- ✅ `docker-compose-armv7.yml` - 部署配置
- ✅ `.github/workflows/build-armv7.yml` - GitHub Actions工作流
- ✅ 完整的文档和说明

## 🎯 5分钟快速设置

### 步骤1：创建GitHub仓库

```bash
# 初始化Git仓库
git init
git add .
git commit -m "Add ARMv7 build support with GitHub Actions"

# 在GitHub上创建新仓库，然后：
git remote add origin https://github.com/YOUR_USERNAME/sgcc_electricity_new.git
git branch -M main
git push -u origin main
```

### 步骤2：设置Docker Hub密钥

1. 访问你的GitHub仓库页面
2. 点击 **Settings** → **Secrets and variables** → **Actions**
3. 添加以下secrets：
   - `DOCKERHUB_USERNAME`: 你的Docker Hub用户名
   - `DOCKERHUB_TOKEN`: 你的Docker Hub访问令牌

### 步骤3：触发构建

```bash
# 推送代码即可触发自动构建
git push

# 或者在GitHub仓库页面手动触发：
# Actions → Build ARMv7 Docker Image → Run workflow
```

### 步骤4：等待构建完成

- 构建时间约10-15分钟
- 在GitHub Actions页面可以查看构建进度
- 构建成功后镜像会自动推送到Docker Hub

### 步骤5：在ARMv7设备上使用

```bash
# 拉取镜像
docker pull YOUR_USERNAME/sgcc_electricity:armv7-latest

# 运行容器
docker run -d --name sgcc_electricity \
  --network host \
  -v $(pwd):/data \
  -e PHONE_NUMBER='your_phone_number' \
  -e PASSWORD='your_password' \
  -e HASS_URL='http://homeassistant.local:8123/' \
  -e HASS_TOKEN='your_hass_token' \
  YOUR_USERNAME/sgcc_electricity:armv7-latest
```

## 🔧 Docker Hub Token获取方法

1. 登录 [Docker Hub](https://hub.docker.com/)
2. 点击右上角头像 → **Account Settings**
3. 选择 **Security** → **Access Tokens**
4. 点击 **New Access Token**
5. 输入描述，选择权限，点击 **Generate**
6. 复制生成的token（只显示一次）

## 📊 构建结果

构建成功后，你将获得：
- 优化的ARMv7 Docker镜像
- 自动推送到Docker Hub
- 支持树莓派等ARMv7设备
- 包含完整的依赖和配置

## 🎉 优势

- ✅ **完全自动化** - 推送代码即可构建
- ✅ **免费服务** - GitHub Actions提供免费构建时间
- ✅ **多次构建** - 每次代码更新都会重新构建
- ✅ **版本管理** - 自动生成版本标签
- ✅ **可靠性高** - 在标准Linux环境下构建

## 📝 注意事项

1. **首次设置** 需要创建Docker Hub账号和访问令牌
2. **构建时间** 约10-15分钟，请耐心等待
3. **免费限额** GitHub Actions每月有2000分钟免费时间
4. **自动触发** 每次推送代码都会触发构建

## 🆘 需要帮助？

如果遇到问题：
1. 检查GitHub Actions的构建日志
2. 确认Docker Hub密钥设置正确
3. 查看 `FINAL_BUILD_SOLUTION.md` 详细说明

---

**准备好了吗？开始设置你的ARMv7自动构建系统！** 🚀
