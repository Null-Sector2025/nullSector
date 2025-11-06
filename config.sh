#!/bin/bash

# 配置管理
CONFIG_DIR="/data/adb/nullSector"
MAIN_CONFIG="$CONFIG_DIR/main.conf"
BOOT_SCRIPT="/data/adb/service.d/nullSector_hide.sh"

# 加载配置
load_config() {
    if [ -f "$MAIN_CONFIG" ]; then
        source "$MAIN_CONFIG"
    else
        create_default_config
    fi
}

# 创建默认配置
create_default_config() {
    mkdir -p "$CONFIG_DIR"
    
    cat > "$MAIN_CONFIG" << 'EOF'
# nullSector 主配置文件
DETECTION_LEVEL="standard"
HIDING_MODE="aggressive"
LOG_LEVEL="info"
PERSISTENT_HIDE=true
AUTO_UPDATE=true
BOOT_SERVICE=true
EOF

    log_success "默认配置文件已创建: $MAIN_CONFIG"
}

# 创建开机脚本
create_boot_script() {
    mkdir -p "$(dirname "$BOOT_SCRIPT")"
    
    cat > "$BOOT_SCRIPT" << 'EOF'
#!/system/bin/sh

# nullSector 持久化隐藏服务
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 5
done

# 等待系统完全启动
sleep 30

log -p i -t "nullSector" "启动持久化隐藏服务..."

# 执行隐藏任务
CONFIG_DIR="/data/adb/nullSector"
if [ -d "$CONFIG_DIR" ]; then
    for app_config in "$CONFIG_DIR"/*.cfg; do
        if [ -f "$app_config" ]; then
            package_name=$(basename "$app_config" .cfg)
            log -p i -t "nullSector" "隐藏应用: $package_name"
            
            # 执行隐藏操作
            /data/data/com.termux/files/home/nullSector/root_hider.sh --apply-hide "$package_name"
        fi
    done
fi

log -p i -t "nullSector" "持久化隐藏服务完成"
EOF

    chmod 755 "$BOOT_SCRIPT"
    log_success "开机脚本已创建: $BOOT_SCRIPT"
}

# 保存配置
save_config() {
    local key=$1
    local value=$2
    
    if grep -q "^$key=" "$MAIN_CONFIG" 2>/dev/null; then
        sed -i "s/^$key=.*/$key=$value/" "$MAIN_CONFIG"
    else
        echo "$key=$value" >> "$MAIN_CONFIG"
    fi
}

# 获取配置
get_config() {
    local key=$1
    grep "^$key=" "$MAIN_CONFIG" 2>/dev/null | cut -d'=' -f2
}