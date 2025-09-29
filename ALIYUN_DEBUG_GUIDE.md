# 🔧 阿里云容器镜像服务403错误诊断指南

## ❌ 当前错误
```
Error response from daemon: login attempt to https://registry.cn-hangzhou.aliyuncs.com/v2/ failed with status: 403 Forbidden
```

## 🔍 诊断步骤

### 1. 检查阿里云控制台设置

请访问：https://cr.console.aliyun.com/

#### 1.1 确认命名空间
- 进入 "命名空间管理"
- 确认命名空间名称（应该是你在GitHub Secrets中设置的 `ALIYUN_NAMESPACE`）
- **注意**：命名空间名称必须全小写，不能包含大写字母或特殊字符

#### 1.2 确认访问凭证
- 进入 "访问凭证" 页面
- 点击 "设置Registry登录密码"
- 记录用户名格式（通常是邮箱或子账号名）

#### 1.3 确认仓库地址
- 在 "镜像仓库" 中查看你的仓库
- 确认地址格式：`registry.cn-hangzhou.aliyuncs.com/[命名空间]/[仓库名]`

### 2. 检查GitHub Secrets配置

在GitHub仓库中检查以下Secrets：

- `ALIYUN_USERNAME` - 阿里云容器镜像服务用户名
- `ALIYUN_PASSWORD` - 阿里云容器镜像服务密码
- `ALIYUN_NAMESPACE` - 命名空间（必须全小写）

### 3. 常见错误修复

#### 错误1：用户名格式错误
- ❌ 错误：使用阿里云账号名
- ✅ 正确：使用容器镜像服务的Registry用户名

#### 错误2：密码错误
- ❌ 错误：使用阿里云登录密码
- ✅ 正确：使用容器镜像服务的Registry密码

#### 错误3：命名空间格式错误
- ❌ 错误：包含大写字母或特殊字符
- ✅ 正确：全小写，只包含字母、数字、短划线

#### 错误4：地域错误
- ❌ 错误：使用错误的地域endpoint
- ✅ 正确：`registry.cn-hangzhou.aliyuncs.com`（杭州）

## ✅ 修复建议

### 方案1：重新配置访问凭证
1. 进入阿里云控制台 → 容器镜像服务
2. 点击 "访问凭证" → "设置Registry登录密码"
3. 重新设置密码
4. 更新GitHub Secrets

### 方案2：创建新的命名空间
1. 进入 "命名空间管理"
2. 创建新的命名空间（全小写，例如：`helloworld-lin`）
3. 更新GitHub Secrets中的 `ALIYUN_NAMESPACE`

### 方案3：使用临时访问凭证
1. 进入 "访问凭证" → "临时访问凭证"
2. 获取临时用户名和密码
3. 在GitHub Secrets中使用临时凭证

## 🧪 本地测试命令

在配置完成后，可以本地测试登录：

```bash
# 测试阿里云登录
docker login registry.cn-hangzhou.aliyuncs.com
# 输入用户名和密码

# 如果成功，应该看到：
# Login Succeeded
```

## 📋 检查清单

- [ ] 命名空间存在且格式正确（全小写）
- [ ] Registry用户名正确
- [ ] Registry密码正确
- [ ] GitHub Secrets已更新
- [ ] 本地可以成功登录测试

完成检查后，重新触发GitHub Actions构建。
