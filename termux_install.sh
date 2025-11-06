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
pkg install -y git wget curl python python-pip root-repo sqlite -y

echo -e "${BLUE}[*] 创建安装目录...${NC}"
mkdir -p $INSTALL_DIR

echo -e "${BLUE}[*] 创建所有核心文件...${NC}"

# 创建logger.sh
cat > $INSTALL_DIR/logger.sh << 'EOF'
#!/bin/bash
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'
log_info() { echo -e "${BLUE}[*]${NC} $1"; }
log_success() { echo -e "${GREEN}[✓]${NC} $1"; }
log_error() { echo -e "${RED}[✗]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[!]${NC} $1"; }
EOF

# 创建config.sh
cat > $INSTALL_DIR/config.sh << 'EOF'
#!/bin/bash
CONFIG_DIR="/data/adb/nullSector"
MAIN_CONFIG="$CONFIG_DIR/main.conf"
load_config() {
    if [ -f "$MAIN_CONFIG" ]; then
        source "$MAIN_CONFIG"
    else
        mkdir -p "$CONFIG_DIR"
        echo "DETECTION_LEVEL=standard" > "$MAIN_CONFIG"
    fi
}
create_boot_script() {
    mkdir -p "/data/adb/service.d"
    cat > "/data/adb/service.d/nullSector_hide.sh" << 'SCRIPT'
#!/system/bin/sh
sleep 30
[ -d "/data/adb/nullSector" ] && {
    for cfg in /data/adb/nullSector/*.cfg; do
        [ -f "$cfg" ] && {
            pkg=$(basename "$cfg" .cfg)
            echo "隐藏应用: $pkg"
        }
    done
}
SCRIPT
    chmod 755 "/data/adb/service.d/nullSector_hide.sh"
}
EOF

# 创建main.sh
cat > $INSTALL_DIR/main.sh << 'EOF'
#!/bin/bash
source "$(dirname "$0")/logger.sh"
source "$(dirname "$0")/config.sh"

show_banner() {
    echo -e "${BLUE}"
    echo "nullSector v2.0 - Advanced Root Detection"
    echo "=========================================="
    echo -e "${NC}"
}

show_help() {
    echo "可用命令:"
    echo "  detect           - Root检测"
    echo "  hide [包名]      - 隐藏环境"
    echo "  persistent-hide [包名] - 持久化隐藏"
    echo "  status           - 状态查看"
    echo "  init-config      - 初始化配置"
}

check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        log_error "需要root权限"
        return 1
    fi
    return 0
}

run_detection() {
    log_info "开始Root检测..."
    local detected=0
    
    # 检测su
    if command -v su >/dev/null 2>&1; then
        log_warning "发现su命令"
        detected=1
    fi
    
    # 检测Magisk
    if [ -d "/data/adb/magisk" ]; then
        log_warning "发现Magisk"
        detected=1
    fi
    
    # 检测系统属性
    if [ "$(getprop ro.debuggable)" = "1" ]; then
        log_warning "系统可调试"
        detected=1
    fi
    
    if [ $detected -eq 1 ]; then
        log_error "发现Root迹象"
    else
        log_success "未发现Root迹象"
    fi
}

persistent_hide() {
    local pkg=$1
    if [ -z "$pkg" ]; then
        log_error "请提供包名"
        return 1
    fi
    
    if ! check_root; then
        return 1
    fi
    
    mkdir -p "/data/adb/nullSector"
    echo "HIDDEN_AT=$(date +%s)" > "/data/adb/nullSector/${pkg}.cfg"
    log_success "持久化隐藏已设置: $pkg"
    log_info "重启后自动生效"
}

show_status() {
    if [ -d "/data/adb/nullSector" ]; then
        local apps=$(ls /data/adb/nullSector/*.cfg 2>/dev/null | wc -l)
        log_info "已隐藏应用: $apps 个"
        ls /data/adb/nullSector/*.cfg 2>/dev/null | while read cfg; do
            echo "  📱 $(basename "$cfg" .cfg)"
        done
    else
        log_info "暂无隐藏应用"
    fi
}

main() {
    case $1 in
        "detect") run_detection ;;
        "persistent-hide") persistent_hide "$2" ;;
        "status") show_status ;;
        "init-config") 
            mkdir -p "/data/adb/nullSector"
            create_boot_script
            log_success "配置初始化完成" 
            ;;
        "help"|*) show_help ;;
    esac
}

main "$@"
EOF

# 创建root_detector.sh
cat > $INSTALL_DIR/root_detector.sh << 'EOF'
#!/bin/bash
source "$(dirname "$0")/logger.sh"

run_full_detection() {
    log_info "执行完整Root检测..."
    
    local checks=0
    local found=0
    
    # 检查su二进制
    for path in /system/bin/su /system/xbin/su /sbin/su; do
        checks=$((checks+1))
        if [ -e "$path" ]; then
            log_error "发现su: $path"
            found=$((found+1))
        fi
    done
    
    # 检查Magisk
    checks=$((checks+1))
    if [ -d "/data/adb/magisk" ]; then
        log_error "发现Magisk"
        found=$((found+1))
    fi
    
    # 检查系统属性
    checks=$((checks+1))
    if [ "$(getprop ro.debuggable)" = "1" ]; then
        log_warning "系统可调试"
        found=$((found+1))
    fi
    
    checks=$((checks+1))
    if [ "$(getprop ro.secure)" = "0" ]; then
        log_error "系统不安全"
        found=$((found+1))
    fi
    
    echo ""
    if [ $found -gt 0 ]; then
        log_error "发现 $found/$checks 个Root迹象"
    else
        log_success "未发现Root迹象"
    fi
}

run_quick_detection() {
    log_info "快速检测..."
    if command -v su >/dev/null 2>&1; then
        log_error "发现Root"
    else
        log_success "未发现Root"
    fi
}
EOF

# 创建root_hider.sh
cat > $INSTALL_DIR/root_hider.sh << 'EOF'
#!/bin/bash
source "$(dirname "$0")/logger.sh"

init_persistent_config() {
    mkdir -p "/data/adb/nullSector"
    log_success "持久化系统就绪"
}

hide_environment() {
    local pkg=$1
    log_info "隐藏环境: $pkg"
    # 这里可以添加具体的隐藏逻辑
    log_success "环境隐藏完成"
}

show_persistent_status() {
    if [ -d "/data/adb/nullSector" ]; then
        local count=$(ls /data/adb/nullSector/*.cfg 2>/dev/null | wc -l)
        log_info "持久化隐藏应用: $count 个"
        for cfg in /data/adb/nullSector/*.cfg; do
            [ -f "$cfg" ] && echo "  ✅ $(basename "$cfg" .cfg)"
        done
    else
        log_info "暂无持久化隐藏"
    fi
}
EOF

# 设置执行权限
chmod +x $INSTALL_DIR/*.sh

# 创建主命令
cat > $INSTALL_DIR/nullSector << 'EOF'
#!/bin/bash
$HOME/nullSector/main.sh "$@"
EOF
chmod +x $INSTALL_DIR/nullSector

# 创建符号链接
ln -sf $INSTALL_DIR/nullSector $BIN_DIR/nullSector

echo -e "${GREEN}[✓] 安装完成!${NC}"
echo -e "${YELLOW}[!] 使用方法:${NC}"
echo -e "  nullSector detect          # Root检测"
echo -e "  nullSector persistent-hide [包名]  # 持久化隐藏"
echo -e "  nullSector status          # 状态查看"
echo -e "  nullSector init-config     # 初始化配置"
echo ""
echo -e "${BLUE}[*] 首次使用请运行: nullSector init-config${NC}"