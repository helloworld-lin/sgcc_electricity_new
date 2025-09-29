## 🚀 阿里云镜像配置完成

### 📋 需要完成的配置

请在GitHub仓库的Secrets中添加以下配置：

1. **ALIYUN_USERNAME**: 你的阿里云账号邮箱
2. **ALIYUN_PASSWORD**: 阿里云容器镜像服务密码  
3. **ALIYUN_NAMESPACE**: helloworld-lin

### 🎯 阿里云镜像地址

配置完成后，你的镜像将推送到：
`registry.cn-hangzhou.aliyuncs.com/helloworld-lin/sgcc_electricity:armv7-latest`

### 🚀 使用方法

```bash
# 国内用户推荐使用阿里云镜像
docker pull registry.cn-hangzhou.aliyuncs.com/helloworld-lin/sgcc_electricity:armv7-latest

docker run -d --name sgcc_electricity \
  --network host \
  -v $(pwd)/data:/data \
  -e PHONE_NUMBER='13800138000' \
  -e PASSWORD='your_password' \
  registry.cn-hangzhou.aliyuncs.com/helloworld-lin/sgcc_electricity:armv7-latest
```

详细配置请参考 ALIYUN_SETUP_GUIDE.md 文件。
