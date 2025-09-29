#!/bin/bash

# 🔄 Docker Hub到阿里云镜像同步测试脚本
# 
# 使用方法：
# 1. 设置环境变量或直接在脚本中填写
# 2. 运行：bash test_mirror_sync.sh
#
# 需要的环境变量：
# - DOCKERHUB_USERNAME: Docker Hub用户名
# - ALIYUN_USERNAME: 阿里云容器镜像服务用户名
# - ALIYUN_PASSWORD: 阿里云容器镜像服务密码
# - ALIYUN_NAMESPACE: 阿里云命名空间

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔄 Docker Hub到阿里云镜像同步测试${NC}"
echo "=================================="

# 检查必要的环境变量
check_env_var() {
    local var_name=$1
    if [ -z "${!var_name}" ]; then
        echo -e "${RED}❌ 环境变量 $var_name 未设置${NC}"
        echo "请设置环境变量或编辑脚本中的值"
        exit 1
    fi
}

# 如果没有设置环境变量，请在这里填写（仅用于测试）
# DOCKERHUB_USERNAME="your_dockerhub_username"
# ALIYUN_USERNAME="your_aliyun_username" 
# ALIYUN_PASSWORD="your_aliyun_password"
# ALIYUN_NAMESPACE="your_aliyun_namespace"

echo -e "${YELLOW}📋 检查环境变量...${NC}"
check_env_var "DOCKERHUB_USERNAME"
check_env_var "ALIYUN_USERNAME"
check_env_var "ALIYUN_PASSWORD"
check_env_var "ALIYUN_NAMESPACE"

# 设置镜像变量
DOCKERHUB_IMAGE="${DOCKERHUB_USERNAME}/sgcc_electricity:armv7-latest"
ALIYUN_IMAGE="registry.cn-hangzhou.aliyuncs.com/${ALIYUN_NAMESPACE}/sgcc_electricity:armv7-latest"

echo -e "${BLUE}📊 镜像信息:${NC}"
echo "Docker Hub: $DOCKERHUB_IMAGE"
echo "阿里云:     $ALIYUN_IMAGE"
echo ""

# 步骤1: 拉取Docker Hub镜像
echo -e "${YELLOW}📥 步骤1: 从Docker Hub拉取镜像...${NC}"
if docker pull "$DOCKERHUB_IMAGE"; then
    echo -e "${GREEN}✅ Docker Hub镜像拉取成功${NC}"
else
    echo -e "${RED}❌ Docker Hub镜像拉取失败${NC}"
    echo "请确认:"
    echo "1. 镜像名称正确"
    echo "2. 镜像已存在于Docker Hub"
    echo "3. 网络连接正常"
    exit 1
fi

# 步骤2: 重新标记镜像
echo -e "${YELLOW}🏷️ 步骤2: 重新标记镜像...${NC}"
if docker tag "$DOCKERHUB_IMAGE" "$ALIYUN_IMAGE"; then
    echo -e "${GREEN}✅ 镜像标记成功${NC}"
else
    echo -e "${RED}❌ 镜像标记失败${NC}"
    exit 1
fi

# 步骤3: 登录阿里云
echo -e "${YELLOW}🔐 步骤3: 登录阿里云容器镜像服务...${NC}"
if echo "$ALIYUN_PASSWORD" | docker login registry.cn-hangzhou.aliyuncs.com -u "$ALIYUN_USERNAME" --password-stdin; then
    echo -e "${GREEN}✅ 阿里云登录成功${NC}"
else
    echo -e "${RED}❌ 阿里云登录失败${NC}"
    echo "请检查:"
    echo "1. 用户名和密码是否正确"
    echo "2. 是否为容器镜像服务的Registry凭证（不是阿里云账号密码）"
    echo "3. 命名空间是否存在"
    exit 1
fi

# 步骤4: 推送到阿里云
echo -e "${YELLOW}📤 步骤4: 推送到阿里云镜像仓库...${NC}"
if docker push "$ALIYUN_IMAGE"; then
    echo -e "${GREEN}✅ 阿里云镜像推送成功${NC}"
else
    echo -e "${RED}❌ 阿里云镜像推送失败${NC}"
    exit 1
fi

# 步骤5: 验证镜像
echo -e "${YELLOW}🔍 步骤5: 验证镜像...${NC}"
echo "检查镜像大小和层信息:"
docker images | grep sgcc_electricity

echo ""
echo -e "${GREEN}🎉 镜像同步完成！${NC}"
echo ""
echo -e "${BLUE}📋 使用说明:${NC}"
echo ""
echo "阿里云镜像（国内推荐）:"
echo "docker pull $ALIYUN_IMAGE"
echo ""
echo "Docker Hub镜像（国外）:"
echo "docker pull $DOCKERHUB_IMAGE"
echo ""
echo -e "${YELLOW}💡 提示: 两个镜像内容完全一致，选择网络访问更快的即可${NC}"
