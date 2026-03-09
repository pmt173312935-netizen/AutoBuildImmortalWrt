#!/bin/bash
# 更新 ImageBuilder 的下载源为国内镜像，确保插件包能被找到
echo "Updating repositories.conf..."

# 使用腾讯云或中科大的镜像源（二选一，推荐腾讯云，Actions 访问较快）
MIRROR_URL="https://mirrors.cloud.tencent.com/immortalwrt"

# 替换默认源
sed -i "s|https://downloads.immortalwrt.org|$MIRROR_URL|g" repositories.conf

# 额外添加第三方核心包地址，确保 AGH 和 MosDNS 这种包能被索引到
# 注意：路径需对应你的 24.10 分支和 x86_64 架构
echo "src/gz custom_luci $MIRROR_URL/releases/24.10.0/packages/x86_64/luci" >> repositories.conf
echo "src/gz custom_base $MIRROR_URL/releases/24.10.0/packages/x86_64/base" >> repositories.conf

echo "✅ Repositories updated successfully."
cat repositories.conf
