#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# 日志函数
log_info() {
    echo -e "${BLUE}[*]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

log_detection() {
    local message=$1
    local level=$2
    
    case $level in
        "critical")
            echo -e "${RED}🚨 CRITICAL: $message${NC}"
            ;;
        "high")
            echo -e "${RED}⚠️  HIGH: $message${NC}"
            ;;
        "medium")
            echo -e "${YELLOW}📝 MEDIUM: $message${NC}"
            ;;
        "low")
            echo -e "${BLUE}ℹ️  LOW: $message${NC}"
            ;;
        *)
            echo -e "${BLUE}ℹ️  INFO: $message${NC}"
            ;;
    esac
}

# 进度条
show_progress() {
    local current=$1
    local total=$2
    local width=50
    local percentage=$((current * 100 / total))
    local completed=$((current * width / total))
    local remaining=$((width - completed))
    
    printf "\r${BLUE}[${NC}"
    printf "%*s" $completed | tr ' ' '='
    printf "%*s" $remaining | tr ' ' '-'
    printf "${BLUE}]${NC} %d%%" $percentage
}