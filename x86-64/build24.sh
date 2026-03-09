#!/bin/bash

source shell/custom-packages.sh
source shell/switch_repository.sh

echo "第三方软件包: $CUSTOM_PACKAGES"

# 基础插件
PACKAGES="curl"
PACKAGES="$PACKAGES luci-theme-argon"
PACKAGES="$PACKAGES luci-app-argon-config"
PACKAGES="$PACKAGES luci-i18n-firewall-zh-cn"
PACKAGES="$PACKAGES luci-i18n-ttyd-zh-cn"
PACKAGES="$PACKAGES openssh-sftp-server"

# DNS组件
PACKAGES="$PACKAGES luci-app-mosdns luci-i18n-mosdns-zh-cn"
PACKAGES="$PACKAGES luci-app-adguardhome"

# 文件管理
PACKAGES="$PACKAGES luci-i18n-filemanager-zh-cn"

# OpenClash
PACKAGES="$PACKAGES luci-app-openclash"

# 合并第三方插件
PACKAGES="$PACKAGES $CUSTOM_PACKAGES"

echo "安装插件:"
echo "$PACKAGES"

# OpenClash core 自动下载
mkdir -p files/etc/openclash/core

echo "下载 OpenClash Core"

wget -qO- https://raw.githubusercontent.com/vernesong/OpenClash/core/master/meta/clash-linux-amd64.tar.gz \
| tar zxO > files/etc/openclash/core/clash_meta

chmod +x files/etc/openclash/core/clash_meta

# GEOIP
wget -q https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat \
-O files/etc/openclash/GeoIP.dat

wget -q https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat \
-O files/etc/openclash/GeoSite.dat

echo "开始构建固件..."

make image PROFILE="x86-64" \
PACKAGES="$PACKAGES" \
FILES="files" \
ROOTFS_PARTSIZE=1024

if [ $? -ne 0 ]; then
    echo "构建失败"
    exit 1
fi

echo "构建完成"
