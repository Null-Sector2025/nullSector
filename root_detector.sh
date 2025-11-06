#!/bin/bash

source "$(dirname "$0")/logger.sh"

# 原创研发的检测方法
ORIGINAL_DETECTION_METHODS=(
    "check_superuser_binary"
    "check_root_apps"
    "check_su_command"
    "check_busybox"
    "check_xposed"
    "check_magisk"
    "check_system_props"
    "check_rw_system"
    "check_dangerous_files"
    "check_selinux"
    "check_test_keys"
    "check_dangerous_ports"
    "check_su_daemon"
)

# 检测Superuser二进制文件
check_superuser_binary() {
    local detected=0
    local su_paths=(
        "/system/bin/su"
        "/system/xbin/su"
        "/sbin/su"
        "/system/sd/xbin/su"
        "/system/bin/failsafe/su"
        "/data/local/su"
        "/data/local/bin/su"
        "/data/local/xbin/su"
    )
    
    for path in "${su_paths[@]}"; do
        if [ -e "$path" ]; then
            log_detection "发现Superuser二进制: $path" "high"
            detected=1
        fi
    done
    
    return $detected
}

# 检测Root应用
check_root_apps() {
    local detected=0
    local root_apps=(
        "com.topjohnwu.magisk"
        "eu.chainfire.supersu"
        "com.noshufou.android.su"
        "com.thirdparty.superuser"
        "com.koushikdutta.superuser"
    )
    
    for app in "${root_apps[@]}"; do
        if pm list packages | grep -q "$app"; then
            log_detection "发现Root应用: $app" "high"
            detected=1
        fi
    done
    
    return $detected
}

# 检测su命令
check_su_command() {
    if command -v su >/dev/null 2>&1; then
        # 测试su命令是否工作
        if su -c "echo test" 2>/dev/null | grep -q "test"; then
            log_detection "su命令可用且具有root权限" "critical"
            return 1
        fi
    fi
    return 0
}

# 检测Magisk
check_magisk() {
    local detected=0
    
    # 检查Magisk路径
    local magisk_paths=(
        "/sbin/.magisk"
        "/dev/magisk"
        "/data/adb/magisk"
        "/cache/magisk"
    )
    
    for path in "${magisk_paths[@]}"; do
        if [ -e "$path" ]; then
            log_detection "发现Magisk路径: $path" "high"
            detected=1
        fi
    done
    
    # 检查Magisk模块
    if [ -d "/data/adb/modules" ]; then
        local module_count=$(find /data/adb/modules -maxdepth 1 -type d | wc -l)
        if [ "$module_count" -gt 1 ]; then
            log_detection "发现Magisk模块 ($((module_count-1))个)" "medium"
            detected=1
        fi
    fi
    
    return $detected
}

# 检测系统属性
check_system_props() {
    local detected=0
    
    # 检查ro.debuggable
    local debuggable=$(getprop ro.debuggable)
    if [ "$debuggable" = "1" ]; then
        log_detection "系统可调试 (ro.debuggable=1)" "medium"
        detected=1
    fi
    
    # 检查ro.secure
    local secure=$(getprop ro.secure)
    if [ "$secure" = "0" ]; then
        log_detection "系统不安全 (ro.secure=0)" "high"
        detected=1
    fi
    
    # 检查ro.build.tags
    local build_tags=$(getprop ro.build.tags)
    if [[ "$build_tags" == *"test-keys"* ]]; then
        log_detection "使用测试密钥构建" "medium"
        detected=1
    fi
    
    return $detected
}

# 检测系统可写
check_rw_system() {
    # 尝试在/system分区创建文件
    if touch /system/test_rw 2>/dev/null; then
        rm -f /system/test_rw 2>/dev/null
        log_detection "/system分区可写" "critical"
        return 1
    fi
    return 0
}

# 运行完整检测
run_full_detection() {
    log_info "开始完整Root检测..."
    local total_detections=0
    
    for method in "${ORIGINAL_DETECTION_METHODS[@]}"; do
        if $method; then
            total_detections=$((total_detections + 1))
        fi
    done
    
    # 显示检测结果
    echo ""
    if [ $total_detections -gt 0 ]; then
        log_error "⚠️  发现 $total_detections 个Root迹象"
        log_info "建议使用 'nullSector persistent-hide' 命令持久化隐藏环境"
    else
        log_success "✅ 未发现明显的Root迹象"
    fi
}

# 快速检测
run_quick_detection() {
    log_info "执行快速Root检测..."
    
    local quick_methods=(
        "check_superuser_binary"
        "check_su_command"
        "check_magisk"
    )
    
    local detected=0
    for method in "${quick_methods[@]}"; do
        if $method; then
            detected=1
        fi
    done
    
    if [ $detected -eq 1 ]; then
        log_error "发现Root迹象"
    else
        log_success "未发现明显的Root迹象"
    fi
}