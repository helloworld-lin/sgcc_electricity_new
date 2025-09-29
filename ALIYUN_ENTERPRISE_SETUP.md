# 🏢 阿里云容器镜像服务企业版配置指南

## 📋 个人版 vs 企业版对比

| 功能 | 个人版 | 企业版 |
|------|--------|--------|
| **价格** | 免费 | 按需付费（很便宜） |
| **镜像仓库数量** | 300个 | 无限制 |
| **命名空间** | 3个 | 无限制 |
| **网络访问** | 公网 | 公网+VPC |
| **API支持** | 基础 | 完整 |
| **自动化构建** | 有限 | 完整支持 |
| **域名** | `crpi-xxx.personal.cr.aliyuncs.com` | `registry.cn-region.aliyuncs.com` |

## 🚀 升级到企业版（推荐）

### 第一步：开通企业版服务

1. **访问阿里云控制台**
   ```
   https://cr.console.aliyun.com/
   ```

2. **选择企业版**
   - 点击左侧菜单 "容器镜像服务企业版"
   - 如果没有开通，会提示开通服务
   - 选择地域（推荐：华东1-杭州）

3. **创建企业版实例**
   - 实例名称：`sgcc-electricity-registry`
   - 实例规格：标准版（够用且便宜）
   - 地域：华东1（杭州）
   - 网络类型：公网访问

### 第二步：配置命名空间和仓库

1. **创建命名空间**
   ```
   命名空间名称: helloworld-lin
   可见性: 公开（或私有，看你需求）
   ```

2. **创建镜像仓库**
   ```
   仓库名称: sgcc_electricity
   仓库类型: 公开（推荐）或私有
   摘要: SGCC电力查询ARMv7镜像
   ```

### 第三步：获取访问凭证

1. **进入访问凭证页面**
   - 在企业版实例中点击 "访问凭证"
   - 设置Registry登录密码

2. **记录关键信息**
   ```bash
   # 企业版配置信息
   Registry地址: registry.cn-hangzhou.aliyuncs.com
   用户名: [你的阿里云账号邮箱或子账号名]
   密码: [刚才设置的Registry密码]
   命名空间: helloworld-lin
   完整镜像地址: registry.cn-hangzhou.aliyuncs.com/helloworld-lin/sgcc_electricity:armv7-latest
   ```

## ⚙️ GitHub Secrets配置

在GitHub仓库中设置以下Secrets：

```bash
# 企业版配置
ALIYUN_USERNAME=你的阿里云账号邮箱
ALIYUN_PASSWORD=Registry登录密码
ALIYUN_NAMESPACE=helloworld-lin
```

**注意**：企业版不需要 `ALIYUN_REGISTRY_URL`，因为使用标准地址！

## 🧪 本地测试企业版登录

```bash
# 测试企业版登录
docker login registry.cn-hangzhou.aliyuncs.com
# 输入用户名：你的阿里云账号邮箱
# 输入密码：Registry登录密码

# 如果成功，应该看到：
# Login Succeeded
```

## 💰 费用说明

企业版按使用量计费，非常便宜：

- **存储费用**：0.5元/GB/月
- **流量费用**：0.5元/GB（公网下行）
- **API调用**：免费额度很高

**实际成本估算**：
- 一个ARMv7镜像约500MB
- 每月存储成本：约0.25元
- 正常使用情况下，**每月费用不超过2元**

## 🔄 迁移步骤

如果你决定从个人版迁移到企业版：

### 方案1：重新配置（推荐）
1. 开通企业版
2. 创建新的命名空间和仓库
3. 更新GitHub Secrets
4. 重新运行构建

### 方案2：保持个人版
如果你想继续使用个人版，我们需要修改配置：

```bash
# 个人版配置（你当前的配置）
ALIYUN_USERNAME=aliyun0809566164
ALIYUN_PASSWORD=你的Registry密码
ALIYUN_REGISTRY_URL=crpi-s1ugew53omsoe998.cn-hangzhou.personal.cr.aliyuncs.com
ALIYUN_NAMESPACE=helloworld-lin
```

## 🎯 推荐选择

**强烈推荐企业版**，原因：
1. ✅ 配置更简单标准
2. ✅ 功能更完整
3. ✅ 自动化支持更好
4. ✅ 费用极低（每月不超过2元）
5. ✅ 未来扩展性更好

## 📞 需要帮助？

告诉我你的选择：
- **选择1**：升级到企业版（推荐）
- **选择2**：继续使用个人版

我会相应地调整GitHub Actions配置！
