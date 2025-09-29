#!/bin/bash

# 🔍 阿里云容器镜像服务配置检测脚本

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 阿里云容器镜像服务配置检测${NC}"
echo "=================================="
echo ""

# 检测函数
detect_aliyun_type() {
    echo -e "${YELLOW}📋 请选择你的阿里云容器镜像服务类型：${NC}"
    echo ""
    echo "1) 个人版 (免费)"
    echo "   域名格式: crpi-xxxx.cn-region.personal.cr.aliyuncs.com"
    echo "   你的域名: crpi-s1ugew53omsoe998.cn-hangzhou.personal.cr.aliyuncs.com"
    echo ""
    echo "2) 企业版 (推荐，按量付费)"
    echo "   域名格式: registry.cn-region.aliyuncs.com"
    echo "   标准域名: registry.cn-hangzhou.aliyuncs.com"
    echo ""
    echo "3) 不确定，让我检查"
    echo ""
    read -p "请输入选项 (1/2/3): " choice
    
    case $choice in
        1)
            setup_personal_version
            ;;
        2)
            setup_enterprise_version
            ;;
        3)
            detect_existing_config
            ;;
        *)
            echo -e "${RED}❌ 无效选项${NC}"
            detect_aliyun_type
            ;;
    esac
}

# 个人版配置
setup_personal_version() {
    echo ""
    echo -e "${PURPLE}🏠 个人版配置${NC}"
    echo "=================================="
    
    echo -e "${YELLOW}📝 请设置以下GitHub Secrets:${NC}"
    echo ""
    echo "ALIYUN_USERNAME=aliyun0809566164"
    echo "ALIYUN_PASSWORD=[你的Registry密码]"
    echo "ALIYUN_REGISTRY_URL=crpi-s1ugew53omsoe998.cn-hangzhou.personal.cr.aliyuncs.com"
    echo "ALIYUN_NAMESPACE=helloworld-lin"
    echo ""
    
    echo -e "${BLUE}🧪 本地测试命令:${NC}"
    echo "docker login crpi-s1ugew53omsoe998.cn-hangzhou.personal.cr.aliyuncs.com"
    echo ""
    
    echo -e "${GREEN}✅ 个人版配置完成！${NC}"
    echo "现在可以运行构建了。"
}

# 企业版配置
setup_enterprise_version() {
    echo ""
    echo -e "${PURPLE}🏢 企业版配置（推荐）${NC}"
    echo "=================================="
    
    echo -e "${YELLOW}📋 企业版优势:${NC}"
    echo "✅ 配置更简单"
    echo "✅ 功能更完整" 
    echo "✅ 费用极低（每月<2元）"
    echo "✅ 自动化支持更好"
    echo ""
    
    echo -e "${BLUE}🚀 开通步骤:${NC}"
    echo "1. 访问: https://cr.console.aliyun.com/"
    echo "2. 选择'容器镜像服务企业版'"
    echo "3. 创建实例（选择华东1-杭州）"
    echo "4. 创建命名空间: helloworld-lin"
    echo "5. 创建仓库: sgcc_electricity"
    echo ""
    
    echo -e "${YELLOW}📝 GitHub Secrets配置:${NC}"
    echo "ALIYUN_USERNAME=[你的阿里云账号邮箱]"
    echo "ALIYUN_PASSWORD=[Registry登录密码]" 
    echo "ALIYUN_NAMESPACE=helloworld-lin"
    echo ""
    echo -e "${GREEN}注意: 企业版不需要ALIYUN_REGISTRY_URL${NC}"
    echo ""
    
    echo -e "${BLUE}🧪 本地测试命令:${NC}"
    echo "docker login registry.cn-hangzhou.aliyuncs.com"
    echo ""
    
    read -p "是否已经开通企业版？(y/n): " enterprise_ready
    if [[ $enterprise_ready == "y" || $enterprise_ready == "Y" ]]; then
        echo -e "${GREEN}✅ 企业版配置完成！${NC}"
        echo "现在可以运行构建了。"
    else
        echo -e "${YELLOW}💡 请先按照上述步骤开通企业版，然后重新运行此脚本${NC}"
    fi
}

# 检测现有配置
detect_existing_config() {
    echo ""
    echo -e "${BLUE}🔍 检测现有Docker登录配置...${NC}"
    
    if docker system info >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Docker运行正常${NC}"
        
        # 尝试检测已有的登录配置
        echo ""
        echo -e "${YELLOW}🔐 检测已有登录配置:${NC}"
        
        if grep -q "personal.cr.aliyuncs.com" ~/.docker/config.json 2>/dev/null; then
            echo "检测到个人版配置"
            setup_personal_version
        elif grep -q "registry.cn-.*aliyuncs.com" ~/.docker/config.json 2>/dev/null; then
            echo "检测到企业版配置"
            setup_enterprise_version
        else
            echo "未检测到阿里云配置"
            echo ""
            echo -e "${YELLOW}💡 建议选择企业版（功能更强，费用极低）${NC}"
            detect_aliyun_type
        fi
    else
        echo -e "${RED}❌ Docker未运行，请先启动Docker${NC}"
        exit 1
    fi
}

# 主函数
main() {
    echo -e "${BLUE}💡 根据你之前提供的信息，你目前使用的是个人版${NC}"
    echo "域名: crpi-s1ugew53omsoe998.cn-hangzhou.personal.cr.aliyuncs.com"
    echo ""
    
    detect_aliyun_type
}

# 运行主函数
main
