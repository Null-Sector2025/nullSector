#!/bin/bash

source "$(dirname "$0")/logger.sh"
source "$(dirname "$0")/config.sh"

# 持久化隐藏配置
PERSISTENT_CONFIG_DIR="/data/adb/nullSector"

# 初始化持久化配置
init_persistent_config() {
    mkdir -p "$PERSISTENT_CONFIG_DIR"
    create_boot_script
    log_success "持久化系统初始化完成"
}

# 持久化隐藏应用
persistent_hide() {
    local package_name=$1
    
    if [ -z "$package_name" ]; then
        log_error "请提供应用包名"
        return 1
    fi
    
    # 检查root权限
    if ! check_root; then
        log_error "需要root权限来设置持久化隐藏"
        return 1
    fi
    
    # 保存配置
    local config_file="$PERSISTENT_CONFIG_DIR/${package_name}.cfg"
    cat > "$config_file" << EOF
PACKAGE_NAME=$package_name
HIDE_TIMESTAMP=$(date +%s)
HIDE_MODE=persistent
EOF

    log_success "持久化配置已保存: $config_file"
    
    # 立即执行隐藏
    apply_persistent_hide "$package_name"
    
    log_info "✅ $package_name 已设置持久化隐藏"
    log_info "📱 重启后隐藏效果会自动恢复"
}

# 应用持久化隐藏
apply_persistent_hide() {
    local package_name=$1
    
    log_info "应用持久化隐藏: $package_name"
    
    # 1. 隐藏Root二进制
    hide_root_binaries_persistent
    
    # 2. 修改系统属性
    modify_system_properties_persistent
    
    # 3. 隐藏Magisk
    hide_magisk_persistent
    
    # 4. 配置应用隔离
    setup_app_isolation "$package_name"
    
    log_success "持久化隐藏应用完成"
}

# 隐藏Root环境
hide_environment() {
    local package_name=$1
    
    if [ -z "$package_name" ]; then
        log_error "请提供应用包名"
        return 1
    fi
    
    log_info "开始为 $package_name 隐藏Root环境..."
    
    if ! check_root; then
        log_error "需要root权限来隐藏环境"
        return 1
    fi
    
    # 创建隔离环境
    create_isolation_environment "$package_name"
    
    # 隐藏Root二进制
    hide_root_binaries
    
    # 修改系统属性
    modify_system_properties
    
    # 隐藏Magisk
    hide_magisk
    
    log_success "环境隐藏完成"
}

# 检查root权限
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        return 1
    fi
    return 0
}

# 创建隔离环境
create_isolation_environment() {
    local package_name=$1
    
    log_info "创建隔离环境..."
    
    # 创建应用专用目录
    local isolate_dir="/data/local/tmp/nullSector/$package_name"
    mkdir -p "$isolate_dir"
    
    # 设置环境变量
    echo "export ISOLATED_ENV=1" > "$isolate_dir/env.sh"
    echo "export PACKAGE_NAME=$package_name" >> "$isolate_dir/env.sh"
    
    # 创建虚假的系统属性
    create_fake_props "$package_name"
}

# 创建虚假属性
create_fake_props() {
    local package_name=$1
    
    log_info "修改系统属性..."
    
    # 临时修改属性
    setprop ro.debuggable 0
    setprop ro.secure 1
    setprop ro.build.type user
    setprop ro.build.tags release-keys
}

# 持久化隐藏Root二进制
hide_root_binaries_persistent() {
    log_info "设置持久化Root二进制隐藏..."
    
    # 使用Magisk模块方式（如果可用）
    if [ -d "/data/adb/modules" ]; then
        create_magisk_module
    fi
    
    # 创建系统级隐藏
    create_system_hide
}

# 创建Magisk模块实现持久化
create_magisk_module() {
    local module_dir="/data/adb/modules/nullSector_hide"
    
    mkdir -p "$module_dir"
    
    # 创建模块配置
    cat > "$module_dir/module.prop" << EOF
id=nullSector_hide
name=nullSector Root Hide
version=v1.0
versionCode=1
author=nullSector
description=Persistent root hiding for selected apps
EOF

    # 创建启动脚本
    mkdir -p "$module_dir/post-fs-data.d"
    cat > "$module_dir/post-fs-data.d/nullSector_hide.sh" << 'EOF'
#!/system/bin/sh

# nullSector 早期启动隐藏脚本
MODDIR=${0%/*}

# 等待系统启动
while [ ! -d "/data/data" ]; do
    sleep 1
done

# 隐藏su二进制（安全方式）
hide_su_binaries() {
    # 不删除文件，而是设置权限和属性
    for su_path in /system/bin/su /system/xbin/su /sbin/su; do
        if [ -f "$su_path" ]; then
            chmod 000 "$su_path"
            chown root:root "$su_path"
            chcon u:object_r:system_file:s0 "$su_path"
        fi
    done
}

# 应用系统属性修改
apply_system_props() {
    resetprop ro.debuggable 0
    resetprop ro.secure 1
    resetprop ro.build.type user
    resetprop ro.build.tags release-keys
    resetprop ro.boot.veritymode enforcing
    resetprop ro.boot.vbmeta.device_state locked
}

hide_su_binaries
apply_system_props

# 执行持久化隐藏
CONFIG_DIR="/data/adb/nullSector"
if [ -d "$CONFIG_DIR" ]; then
    for app_config in "$CONFIG_DIR"/*.cfg; do
        if [ -f "$app_config" ]; then
            . "$app_config"
            log -p i -t "nullSector" "应用持久化隐藏: $PACKAGE_NAME"
        fi
    done
fi
EOF

    chmod 755 "$module_dir/post-fs-data.d/nullSector_hide.sh"
    
    # 创建service.sh用于后期启动
    cat > "$module_dir/service.sh" << 'EOF'
#!/system/bin/sh

# nullSector 后期启动服务
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 5
done

# 等待系统完全启动
sleep 30

# 执行应用级隐藏
CONFIG_DIR="/data/adb/nullSector"
if [ -d "$CONFIG_DIR" ]; then
    for app_config in "$CONFIG_DIR"/*.cfg; do
        if [ -f "$app_config" ]; then
            package_name=$(basename "$app_config" .cfg)
            
            # 配置应用级隐藏
            pm disable com.topjohnwu.magisk >/dev/null 2>&1 || true
            
            # 设置应用权限
            pm revoke "$package_name" android.permission.ACCESS_SUPERUSER 2>/dev/null || true
        fi
    done
fi
EOF

    chmod 755 "$module_dir/service.sh"
    log_success "Magisk模块已创建: $module_dir"
}

# 持久化修改系统属性
modify_system_properties_persistent() {
    log_info "设置持久化系统属性修改..."
    
    # 使用resetprop工具（Magisk自带）
    if command -v resetprop >/dev/null 2>&1; then
        resetprop ro.debuggable 0
        resetprop ro.secure 1
        resetprop ro.build.type user
        resetprop ro.build.tags release-keys
        
        # 持久化保存属性修改
        local prop_file="/data/adb/nullSector/system.prop"
        echo "ro.debuggable=0" > "$prop_file"
        echo "ro.secure=1" >> "$prop_file"
        echo "ro.build.type=user" >> "$prop_file"
        echo "ro.build.tags=release-keys" >> "$prop_file"
    fi
}

# 持久化隐藏Magisk
hide_magisk_persistent() {
    log_info "设置持久化Magisk隐藏..."
    
    # 使用Magisk Hide功能
    if command -v magisk >/dev/null 2>&1; then
        magisk --hide
    fi
}

# 配置应用隔离
setup_app_isolation() {
    local package_name=$1
    
    log_info "配置应用隔离: $package_name"
    
    # 禁用Magisk管理器对目标应用的显示
    pm disable com.topjohnwu.magisk >/dev/null 2>&1 || true
    
    # 撤销敏感权限
    pm revoke "$package_name" android.permission.ACCESS_SUPERUSER 2>/dev/null || true
}

# 隐藏Root二进制（临时）
hide_root_binaries() {
    log_info "隐藏Root二进制..."
    
    # 重命名su二进制（临时）
    local su_paths=(
        "/system/bin/su"
        "/system/xbin/su"
        "/sbin/su"
    )
    
    for su_path in "${su_paths[@]}"; do
        if [ -f "$su_path" ]; then
            mv "$su_path" "${su_path}.bak"
            log_info "已隐藏: $su_path"
        fi
    done
}

# 修改系统属性（临时）
modify_system_properties() {
    log_info "修改系统属性..."
    
    setprop ro.debuggable 0
    setprop ro.secure 1
    setprop ro.build.type user
}

# 隐藏Magisk（临时）
hide_magisk() {
    log_info "隐藏Magisk..."
    
    # 重命名Magisk目录
    if [ -d "/data/adb/magisk" ]; then
        mv "/data/adb/magisk" "/data/adb/magisk_hidden"
    fi
    
    # 停止Magisk守护进程
    pkill -f "magisk"
}

# 显示持久化状态
show_persistent_status() {
    if [ -d "$PERSISTENT_CONFIG_DIR" ]; then
        local hidden_apps=($(ls "$PERSISTENT_CONFIG_DIR"/*.cfg 2>/dev/null | xargs -n 1 basename 2>/dev/null | sed 's/.cfg$//'))
        
        if [ ${#hidden_apps[@]} -gt 0 ]; then
            log_info "持久化隐藏的应用:"
            for app in "${hidden_apps[@]}"; do
                local config_file="$PERSISTENT_CONFIG_DIR/${app}.cfg"
                local timestamp=$(grep "HIDE_TIMESTAMP" "$config_file" 2>/dev/null | cut -d'=' -f2)
                local date_str=$(date -d "@$timestamp" 2>/dev/null || echo "未知时间")
                echo "  📱 $app (隐藏于: $date_str)"
            done
            log_success "✅ 这些应用在重启后会自动隐藏Root环境"
        else
            log_info "没有配置持久化隐藏的应用"
        fi
    else
        log_info "持久化系统未初始化，使用 'nullSector init-config' 初始化"
    fi
}

# 恢复原始环境
restore_environment() {
    local package_name=$1
    
    log_info "恢复原始环境..."
    
    if ! check_root; then
        log_error "需要root权限来恢复环境"
        return 1
    fi
    
    # 删除持久化配置
    local config_file="$PERSISTENT_CONFIG_DIR/${package_name}.cfg"
    if [ -f "$config_file" ]; then
        rm -f "$config_file"
        log_success "删除持久化配置: $config_file"
    fi
    
    # 恢复su二进制
    local su_paths=(
        "/system/bin/su"
        "/system/xbin/su"
        "/sbin/su"
    )
    
    for su_path in "${su_paths[@]}"; do
        if [ -f "${su_path}.bak" ]; then
            mv "${su_path}.bak" "$su_path"
            log_info "已恢复: $su_path"
        fi
    done
    
    # 恢复Magisk
    if [ -d "/data/adb/magisk_hidden" ]; then
        mv "/data/adb/magisk_hidden" "/data/adb/magisk"
    fi
    
    pm enable com.topjohnwu.magisk >/dev/null 2>&1 || true
    
    # 删除Magisk模块
    local module_dir="/data/adb/modules/nullSector_hide"
    if [ -d "$module_dir" ]; then
        rm -rf "$module_dir"
        log_info "删除Magisk模块"
    fi
    
    log_success "环境恢复完成，建议重启系统"
}

# 命令行接口
case "${1:-}" in
    "--apply-hide")
        apply_persistent_hide "$2"
        ;;
    "--persistent-status")
        show_persistent_status
        ;;
esac