#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# 导入工具函数
source "$(dirname "$0")/logger.sh"
source "$(dirname "$0")/config.sh"

# 显示横幅
show_banner() {
    echo -e "${BLUE}"
    cat << "EOF"
 _   _ _   _ _     ____  _____ _______ ______ _____  
| \ | | | | | |   / ___||  ___|_   _|  ____|  __ \ 
|  \| | | | | |   \___ \| |_    | | | |__  | |__) |
| |\  | |_| | |___ ___) |  _|   | | |  __| |  _  / 
|_| \_|\___/|_____|____/|_|     |_| |_|    |_| \_\ 
                                                   
EOF
    echo -e "${NC}"
}

# 显示帮助
show_help() {
    echo -e "${GREEN}nullSector - 高级Root检测和环境隐藏工具${NC}"
    echo ""
    echo -e "${YELLOW}使用方法:${NC}"
    echo "  nullSector [命令] [参数]"
    echo ""
    echo -e "${YELLOW}可用命令:${NC}"
    echo "  detect           - 执行完整Root检测"
    echo "  quick            - 快速Root检测" 
    echo "  deep             - 深度Root检测"
    echo "  hide [包名]      - 隐藏指定应用的Root环境"
    echo "  persistent-hide [包名] - 持久化隐藏(重启有效)"
    echo "  patch [包名]     - 强制去除Root弹窗"
    echo "  status           - 显示当前环境状态"
    echo "  persistent-status - 显示持久化隐藏状态"
    echo "  restore [包名]   - 恢复原始环境"
    echo "  init-config      - 初始化配置"
    echo "  help             - 显示此帮助信息"
    echo ""
    echo -e "${YELLOW}示例:${NC}"
    echo "  nullSector detect"
    echo "  nullSector persistent-hide com.example.app"
    echo "  nullSector patch com.bank.app"
}

# 初始化配置
init_system() {
    log_info "初始化nullSector系统..."
    mkdir -p /data/adb/nullSector
    mkdir -p /data/local/tmp/nullSector
    create_boot_script
    load_config
    log_success "系统初始化完成"
}

# 主函数
main() {
    local command=$1
    local param=$2
    
    show_banner
    
    case $command in
        "init-config")
            init_system
            ;;
        "detect")
            log_info "开始完整Root检测..."
            source "$(dirname "$0")/root_detector.sh"
            run_full_detection
            ;;
        "quick")
            log_info "开始快速Root检测..."
            source "$(dirname "$0")/root_detector.sh"
            run_quick_detection
            ;;
        "deep")
            log_info "开始深度Root检测..."
            source "$(dirname "$0")/advanced_scanner.sh"
            run_deep_scan
            ;;
        "hide")
            if [ -z "$param" ]; then
                log_error "请提供应用包名"
                echo "用法: nullSector hide [包名]"
                return 1
            fi
            log_info "开始隐藏环境: $param"
            source "$(dirname "$0")/root_hider.sh"
            hide_environment "$param"
            ;;
        "persistent-hide")
            if [ -z "$param" ]; then
                log_error "请提供应用包名"
                echo "用法: nullSector persistent-hide [包名]"
                return 1
            fi
            log_info "设置持久化隐藏: $param"
            source "$(dirname "$0")/root_hider.sh"
            init_persistent_config
            persistent_hide "$param"
            ;;
        "patch")
            if [ -z "$param" ]; then
                log_error "请提供应用包名"
                echo "用法: nullSector patch [包名]"
                return 1
            fi
            log_info "开始修补应用: $param"
            source "$(dirname "$0")/app_patcher.sh"
            patch_application "$param"
            ;;
        "status")
            source "$(dirname "$0")/environment_checker.sh"
            check_environment_status
            ;;
        "persistent-status")
            source "$(dirname "$0")/root_hider.sh"
            show_persistent_status
            ;;
        "restore")
            if [ -z "$param" ]; then
                log_error "请提供应用包名"
                echo "用法: nullSector restore [包名]"
                return 1
            fi
            source "$(dirname "$0")/root_hider.sh"
            restore_environment "$param"
            ;;
        "help"|"")
            show_help
            ;;
        *)
            log_error "未知命令: $command"
            show_help
            return 1
            ;;
    esac
}

# 如果脚本直接运行，执行主函数
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi