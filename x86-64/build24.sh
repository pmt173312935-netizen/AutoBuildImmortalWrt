#!/bin/bash

source shell/custom-packages.sh
source shell/switch_repository.sh

LOGFILE="/tmp/uci-defaults-log.txt"

echo "第三方软件包: $CUSTOM_PACKAGES"
echo "Starting build at $(date)" >> $LOGFILE

echo "编译固件大小为: $PROFILE MB"
echo "Include Docker: $INCLUDE_DOCKER"

echo "Create pppoe-settings"

mkdir -p /home/build/immortalwrt/files/etc/config

cat << EOF > /home/build/immortalwrt/files/etc/config/pppoe-settings
enable_pppoe=${ENABLE_PPPOE}
pppoe_account=${PPPOE_ACCOUNT}
pppoe_password=${PPPOE_PASSWORD}
EOF

echo "cat pppoe-settings"
cat /home/build/immortalwrt/files/etc/config/pppoe-settings

# ================= 同步第三方插件 =================

if [ -z "$CUSTOM_PACKAGES" ]; then
  echo "⚪️ 未选择任何第三方软件包"
else
  echo "🔄 正在同步第三方软件仓库..."

  git clone --depth=1 https://github.com/wukongdaily/store.git /tmp/store-run-repo

  mkdir -p /home/build/immortalwrt/extra-packages

  cp -r /tmp/store-run-repo/run/x86/* /home/build/immortalwrt/extra-packages/

  echo "✅ Run files copied:"
  ls -lh /home/build/immortalwrt/extra-packages/*.run

  sh shell/prepare-packages.sh

  ls -lah /home/build/immortalwrt/packages/

  rm -rf /tmp/store-run-repo
fi

echo "$(date '+%Y-%m-%d %H:%M:%S') - 开始构建固件..."

# ================= 固件插件 =================

PACKAGES="\
curl \
luci-theme-argon \
luci-app-argon-config \
luci-i18n-argon-config-zh-cn \
luci-i18n-diskman-zh-cn \
luci-i18n-firewall-zh-cn \
luci-i18n-package-manager-zh-cn \
luci-i18n-ttyd-zh-cn \
luci-app-openclash \
openssh-sftp-server \
luci-app-mosdns \
luci-i18n-mosdns-zh-cn \
luci-i18n-filemanager-zh-cn \
"

# 第三方插件
PACKAGES="$PACKAGES $CUSTOM_PACKAGES"

# Docker
if [ "$INCLUDE_DOCKER" = "yes" ]; then
    PACKAGES="$PACKAGES luci-i18n-dockerman-zh-cn"
    echo "Adding Docker support"
fi

# ================= OpenClash Core =================

if echo "$PACKAGES" | grep -q "luci-app-openclash"; then

    echo "✅ 下载 OpenClash Core"

    mkdir -p /home/build/immortalwrt/files/etc/openclash/core

    META_URL="https://raw.githubusercontent.com/vernesong/OpenClash/core/master/meta/clash-linux-amd64.tar.gz"

    wget -qO- $META_URL | tar xOvz > /home/build/immortalwrt/files/etc/openclash/core/clash_meta

    chmod +x /home/build/immortalwrt/files/etc/openclash/core/clash_meta

    wget -q https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat \
        -O /home/build/immortalwrt/files/etc/openclash/GeoIP.dat

    wget -q https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat \
        -O /home/build/immortalwrt/files/etc/openclash/GeoSite.dat

else
    echo "⚪️ 未选择 OpenClash"
fi

echo "=============================="
echo "构建插件列表:"
echo "$PACKAGES"
echo "=============================="

# ================= 构建固件 =================

make image \
PROFILE="generic" \
PACKAGES="$PACKAGES" \
FILES="/home/build/immortalwrt/files" \
ROOTFS_PARTSIZE=$PROFILE

if [ $? -ne 0 ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ❌ Build failed!"
    exit 1
fi

echo "$(date '+%Y-%m-%d %H:%M:%S') - ✅ Build completed successfully."
