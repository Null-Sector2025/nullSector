#!/bin/bash

echo "
╔═══════════════════════════════════════════╗
║              nullSector v2.0              ║
║         Advanced Root Detection           ║
║              & Environment Hider          ║
╚═══════════════════════════════════════════╝
"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

INSTALL_DIR="$HOME/nullSector"
BIN_DIR="/data/data/com.termux/files/usr/bin"

echo -e "${BLUE}[*] 检查Termux环境...${NC}"
if [ ! -d "/data/data/com.termux/files/usr" ]; then
    echo -e "${RED}错误: 此脚本必须在Termux环境中运行${NC}"
    exit 1
fi

echo -e "${BLUE}[*] 更新包管理器...${NC}"
pkg update -y && pkg upgrade -y

echo -e "${BLUE}[*] 安装依赖...${NC}"
pkg install -y git wget curl python root-repo -y

echo -e "${BLUE}[*] 创建安装目录...${NC}"
mkdir -p $INSTALL_DIR

echo -e "${BLUE}[*] 下载核心文件...${NC}"
cd $INSTALL_DIR

# 下载所有脚本文件
echo -e "${BLUE}[*] 下载 LICENSE...${NC}"
curl -s -o LICENSE "https://raw.githubusercontent.com/Null-Sector2025/nullSector/main/LICENSE"

echo -e "${BLUE}[*] 下载 README.md...${NC}"
curl -s -o README.md "https://raw.githubusercontent.com/Null-Sector2025/nullSector/main/README.md"

echo -e "${BLUE}[*] 下载 logger.sh...${NC}"
curl -s -o logger.sh "https://raw.githubusercontent.com/Null-Sector2025/nullSector/main/logger.sh"

echo -e "${BLUE}[*] 下载 config.sh...${NC}"
curl -s -o config.sh "https://raw.githubusercontent.com/Null-Sector2025/nullSector/main/config.sh"

echo -e "${BLUE}[*] 下载 main.sh...${NC}"
curl -s -o main.sh "https://raw.githubusercontent.com/Null-Sector2025/nullSector/main/main.sh"

echo -e "${BLUE}[*] 下载 root_detector.sh...${NC}"
curl -s -o root_detector.sh "https://raw.githubusercontent.com/Null-Sector2025/nullSector/main/root_detector.sh"

echo -e "${BLUE}[*] 下载 root_hider.sh...${NC}"
curl -s -o root_hider.sh "https://raw.githubusercontent.com/Null-Sector2025/nullSector/main/root_hider.sh"

echo -e "${BLUE}[*] 下载 advanced_scanner.sh...${NC}"
curl -s -o advanced_scanner.sh "https://raw.githubusercontent.com/Null-Sector2025/nullSector/main/advanced_scanner.sh"

echo -e "${BLUE}[*] 下载 app_patcher.sh...${NC}"
curl -s -o app_patcher.sh "https://raw.githubusercontent.com/Null-Sector2025/nullSector/main/app_patcher.sh"

echo -e "${BLUE}[*] 下载 environment_checker.sh...${NC}"
curl -s -o environment_checker.sh "https://raw.githubusercontent.com/Null-Sector2025/nullSector/main/environment_checker.sh"

echo -e "${BLUE}[*] 下载 environment_maker.sh...${NC}"
curl -s -o environment_maker.sh "https://raw.githubusercontent.com/Null-Sector2025/nullSector/main/environment_maker.sh"

echo -e "${BLUE}[*] 设置执行权限...${NC}"
chmod +x $INSTALL_DIR/*.sh

# 创建主命令
cat > $INSTALL_DIR/nullSector << 'EOF'
#!/bin/bash
$HOME/nullSector/main.sh "$@"
EOF
chmod +x $INSTALL_DIR/nullSector

# 创建符号链接
echo -e "${BLUE}[*] 创建命令链接...${NC}"
ln -sf $INSTALL_DIR/nullSector $BIN_DIR/nullSector

echo -e "${GREEN}[✓] 安装完成!${NC}"
echo -e "${YELLOW}[!] 使用方法: nullSector [命令]${NC}"
echo -e "${BLUE}[*] 输入 'nullSector help' 查看帮助${NC}"
echo -e "${BLUE}[*] 首次使用请运行: nullSector init-config${NC}"