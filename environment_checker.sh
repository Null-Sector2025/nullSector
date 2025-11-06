#!/bin/bash

source "$(dirname "$0")/logger.sh"

# 环境检查函数
check_environment_status() {
    log_info "检查当前环境状态..."
    
    # 检测Root状态
    check_root_status
    
    # 检测隐藏状态
    check_hide_status
    
    # 检测系统完整性
    check_system_integrity
    
    # 检测持久化状态
    check_persistent_status
}

check_root_status() {
    log_info "=== Root状态检测 ==="
    
    # 检查su命令
    if command -v su >/dev/null 2>&1; then
        log_warning "su命令存在"
    else
        log_success "su命令未找到"
    fi
    
    # 检查Magisk
    if [ -d "/data/adb/magisk" ]; then
        log_warning "Magisk已安装"
    else
        log_success "Magisk未安装"
    fi
    
    # 检查系统属性
    local debuggable=$(getprop ro.debuggable)
    if [ "$debuggable" = "1" ]; then
        log_warning "系统可调试 (ro.debuggable=1)"
    else
        log_success "系统不可调试"
    fi
}

check_hide_status() {
    log_info "=== 隐藏状态检测 ==="
    
    # 检查nullSector配置
    if [ -d "/data/adb/nullSector" ]; then
        local hidden_count=$(ls /data/adb/nullSector/*.cfg 2>/dev/null | wc -l)
        log_info "已配置 $hidden_count 个隐藏应用"
    else
        log_warning "nullSector未初始化"
    fi
    
    # 检查开机脚本
    if [ -f "/data/adb/service.d/nullSector_hide.sh" ]; then
        log_success "持久化服务已安装"
    else
        log_warning "持久化服务未安装"
    fi
}

check_system_integrity() {
    log_info "=== 系统完整性检测 ==="
    
    # 检查SELinux状态
    local selinux=$(getenforce)
    if [ "$selinux" = "Enforcing" ]; then
        log_success "SELinux: Enforcing"
    else
        log_warning "SELinux: $selinux"
    fi
    
    # 检查系统分区
    if mount | grep -q " /system "; then
        local ro=$(mount | grep " /system " | grep -o ro)
        if [ "$ro" = "ro" ]; then
            log_success "/system 只读挂载"
        else
            log_error "/system 可写挂载"
        fi
    fi
}

check_persistent_status() {
    log_info "=== 持久化状态检测 ==="
    
    if [ -f "/data/adb/service.d/nullSector_hide.sh" ]; then
        log_success "✅ 持久化服务: 已安装"
        log_info "重启后隐藏效果会自动恢复"
    else
        log_error "❌ 持久化服务: 未安装"
        log_info "使用 'nullSector persistent-hide' 启用持久化"
    fi
}