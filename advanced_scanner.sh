#!/bin/bash

source "$(dirname "$0")/logger.sh"

# 高级扫描函数
run_deep_scan() {
    log_info "开始深度扫描..."
    
    # 内存分析
    analyze_memory
    
    # 进程监控
    monitor_processes
    
    # 网络检测
    check_network
    
    # 硬件检测
    check_hardware
    
    # 高级Root检测
    advanced_root_check
    
    log_success "深度扫描完成"
}

analyze_memory() {
    log_info "分析内存..."
    
    # 检查可疑进程
    local suspicious_procs=$(ps -ef | grep -E "(su|magisk|superuser)" | grep -v grep)
    if [ -n "$suspicious_procs" ]; then
        log_detection "发现可疑进程:" "high"
        echo "$suspicious_procs"
    else
        log_success "未发现可疑进程"
    fi
}

monitor_processes() {
    log_info "监控进程..."
    
    # 检查隐藏进程
    local hidden_procs=$(ps -ef | grep -v "\[" | grep -v "]" | tail -n +2)
    local total_procs=$(echo "$hidden_procs" | wc -l)
    log_info "当前运行进程: $total_procs 个"
    
    # 检查特权进程
    local root_procs=$(ps -ef | grep "^root" | wc -l)
    log_info "Root权限进程: $root_procs 个"
}

check_network() {
    log_info "检查网络..."
    
    # 检查网络连接
    local net_connections=$(netstat -tunlp 2>/dev/null | grep -v "127.0.0.1" | grep -v "::1:" | wc -l)
    log_info "活跃网络连接: $net_connections 个"
    
    # 检查可疑端口
    check_suspicious_ports
}

check_suspicious_ports() {
    local suspicious_ports=("1337" "4444" "5555" "6666")
    for port in "${suspicious_ports[@]}"; do
        if netstat -tunlp 2>/dev/null | grep -q ":$port"; then
            log_detection "发现可疑端口监听: $port" "medium"
        fi
    done
}

check_hardware() {
    log_info "检查硬件..."
    
    # 检查调试接口
    if [ -e "/sys/class/android_usb/android0/enable" ]; then
        local usb_debug=$(cat /sys/class/android_usb/android0/enable 2>/dev/null)
        if [ "$usb_debug" = "1" ]; then
            log_warning "USB调试已启用"
        fi
    fi
}

advanced_root_check() {
    log_info "执行高级Root检测..."
    
    # 检查隐藏的su文件
    check_hidden_su_files
    
    # 检查模块加载
    check_module_loading
    
    # 检查系统调用
    check_system_calls
}

check_hidden_su_files() {
    log_info "扫描隐藏的su文件..."
    
    # 在所有可能的位置查找su文件
    local found_su=$(find /system /data /vendor -name "*su*" -type f 2>/dev/null | grep -v "\.so" | head -10)
    if [ -n "$found_su" ]; then
        log_detection "发现可能的su文件:" "medium"
        echo "$found_su" | while read file; do
            echo "  📁 $file"
        done
    fi
}

check_module_loading() {
    log_info "检查内核模块..."
    
    # 检查加载的模块
    if [ -f "/proc/modules" ]; then
        local modules=$(cat /proc/modules | wc -l)
        log_info "已加载内核模块: $modules 个"
    fi
}

check_system_calls() {
    log_info "检查系统调用..."
    
    # 检查ptrace等调试功能
    if [ -f "/proc/sys/kernel/yama/ptrace_scope" ]; then
        local ptrace_scope=$(cat /proc/sys/kernel/yama/ptrace_scope)
        if [ "$ptrace_scope" = "0" ]; then
            log_warning "ptrace调试未限制"
        fi
    fi
}