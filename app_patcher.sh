#!/bin/bash

source "$(dirname "$0")/logger.sh"

# 修补应用去除Root检测
patch_application() {
    local package_name=$1
    
    if [ -z "$package_name" ]; then
        log_error "请提供应用包名"
        return 1
    fi
    
    log_info "开始修补应用: $package_name"
    
    # 检查应用是否安装
    if ! pm list packages | grep -q "$package_name"; then
        log_error "应用未安装: $package_name"
        return 1
    fi
    
    # 获取应用路径
    local app_path=$(pm path "$package_name" | cut -d: -f2)
    if [ -z "$app_path" ]; then
        log_error "无法获取应用路径"
        return 1
    fi
    
    log_info "应用路径: $app_path"
    
    # 创建备份
    create_backup "$app_path" "$package_name"
    
    # 修补应用配置
    modify_app_config "$package_name"
    
    # 清除应用数据
    clear_app_data "$package_name"
    
    log_success "应用修补完成"
}

# 创建备份
create_backup() {
    local app_path=$1
    local package_name=$2
    local backup_dir="/data/local/tmp/nullSector/backup"
    
    mkdir -p "$backup_dir"
    local backup_file="$backup_dir/${package_name}_$(date +%Y%m%d_%H%M%S).backup"
    
    if cp "$app_path" "$backup_file" 2>/dev/null; then
        log_success "备份创建成功: $backup_file"
    else
        log_warning "备份创建失败，继续执行..."
    fi
}

# 修改应用配置
modify_app_config() {
    local package_name=$1
    
    log_info "修改应用配置..."
    
    # 修改应用权限
    pm revoke "$package_name" android.permission.ACCESS_SUPERUSER 2>/dev/null || true
    
    # 设置应用运行时权限
    set_app_runtime_permissions "$package_name"
    
    # 修改应用存储配置
    modify_app_storage "$package_name"
}

# 设置应用运行时权限
set_app_runtime_permissions() {
    local package_name=$1
    
    log_info "设置运行时权限..."
    
    # 拒绝敏感权限
    local dangerous_permissions=(
        "android.permission.READ_LOGS"
        "android.permission.WRITE_SECURE_SETTINGS"
        "android.permission.ACCESS_SUPERUSER"
    )
    
    for permission in "${dangerous_permissions[@]}"; do
        pm revoke "$package_name" "$permission" 2>/dev/null || true
    done
}

# 修改应用存储配置
modify_app_storage() {
    local package_name=$1
    
    log_info "配置存储隔离..."
    
    # 创建应用专用存储
    local app_storage="/data/local/tmp/nullSector/storage/$package_name"
    mkdir -p "$app_storage"
    
    # 设置存储重定向（如果支持）
    if command -v am >/dev/null 2>&1; then
        am broadcast -a "nullSector.STORAGE_REDIRECT" --es "package" "$package_name" --es "path" "$app_storage" >/dev/null 2>&1 || true
    fi
}

# 清除应用数据
clear_app_data() {
    local package_name=$1
    
    read -p "是否清除应用数据？(y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "清除应用数据..."
        pm clear "$package_name"
        log_success "应用数据已清除"
    else
        log_info "跳过数据清除"
    fi
}

# 恢复应用备份
restore_backup() {
    local package_name=$1
    
    local backup_dir="/data/local/tmp/nullSector/backup"
    local latest_backup=$(ls -t "$backup_dir/${package_name}"_*.backup 2>/dev/null | head -1)
    
    if [ -z "$latest_backup" ]; then
        log_error "找不到备份文件"
        return 1
    fi
    
    local app_path=$(pm path "$package_name" | cut -d: -f2)
    if [ -z "$app_path" ]; then
        log_error "无法获取应用路径"
        return 1
    fi
    
    log_info "恢复备份: $latest_backup -> $app_path"
    
    if cp "$latest_backup" "$app_path"; then
        log_success "备份恢复成功"
        # 重新安装应用
        pm install -r "$app_path" >/dev/null 2>&1
    else
        log_error "备份恢复失败"
    fi
}