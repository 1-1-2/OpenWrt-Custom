#!/bin/bash
#
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#

clean_content() {
#=========================================
# 清理重开
#=========================================
rm -f ./.config*
#=========================================
# Target System
#=========================================
cat >> .config <<EOF
CONFIG_TARGET_ramips=y
CONFIG_TARGET_ramips_mt7621=y
CONFIG_TARGET_ramips_mt7621_DEVICE_d-team_newifi-d2=y
EOF
#=========================================
# Stripping options
#=========================================
cat >> .config <<EOF
CONFIG_STRIP_KERNEL_EXPORTS=y
# CONFIG_USE_MKLIBS=y
EOF
#=========================================
# Remove defaults app
#=========================================
cat >> .config <<EOF
# ----------luci-app-ssr-plus
# CONFIG_PACKAGE_luci-app-ssr-plus is not set
EOF
}

basic_content() {
clean_content
#=========================================
# 基础包和应用
#=========================================
cat >> .config <<EOF
# ----------extra packages-automount
CONFIG_PACKAGE_automount=y
# ----------extra packages-ipv6helper
CONFIG_PACKAGE_ipv6helper=y
# ----------Utilities-Disc-cfdisk
CONFIG_PACKAGE_cfdisk=y
# ----------Utilities-usbutils
CONFIG_PACKAGE_usbutils=y
# ----------Utilities-coreutils-base64
CONFIG_PACKAGE_coreutils-base64=y
# ----------Kernel modules-USB Support-kmod-usb3
CONFIG_DEFAULT_kmod-usb3=y
# ----------luci-app-hd-idle
CONFIG_PACKAGE_luci-app-hd-idle=y
# ----------luci-app-cifsd
CONFIG_PACKAGE_luci-app-cifsd=y
# ----------luci-app-commands
CONFIG_PACKAGE_luci-app-commands=y
# ----------luci-app-qos
CONFIG_PACKAGE_luci-app-qos=y
# ----------luci-app-eqos
CONFIG_PACKAGE_luci-app-eqos=y
# ----------luci-app-sqm
CONFIG_PACKAGE_luci-app-sqm=y
# ----------luci-app-ttyd
CONFIG_PACKAGE_luci-app-ttyd=y
# ----------luci-app-wrtbwmon
CONFIG_PACKAGE_luci-app-wrtbwmon=y
# ----------luci-theme-argon
# CONFIG_PACKAGE_luci-theme-argon=y
CONFIG_PACKAGE_luci-app-argon-config=y
# ----------luci-app-webadmin
CONFIG_PACKAGE_luci-app-webadmin=y
EOF
}

func_content() {
basic_content
#=========================================
# 功能包
#=========================================
cat >> .config <<EOF
# ----------luci-app-aria2
CONFIG_PACKAGE_luci-app-aria2=y
# ----------luci-app-jd-dailybonus
CONFIG_PACKAGE_luci-app-jd-dailybonus=y
CONFIG_PACKAGE_luci-app-unblockmusic_INCLUDE_UnblockNeteaseMusic_NodeJS=y
# ----------luci-app-unblockmusic_Go
CONFIG_PACKAGE_luci-app-unblockmusic_INCLUDE_UnblockNeteaseMusic_Go=y
# ----------luci-app-VPNs
CONFIG_PACKAGE_luci-app-nps=y
CONFIG_PACKAGE_luci-app-frpc=y
CONFIG_PACKAGE_luci-app-n2n_v2=y
CONFIG_PACKAGE_luci-app-zerotier=y
# ----------luci-app-openclash
CONFIG_PACKAGE_luci-app-openclash=y
# ----------network-firewall-ip6tables-ip6tables-mod-nat
CONFIG_PACKAGE_ip6tables-mod-nat=y
# ----------luci-app-transmission
CONFIG_PACKAGE_luci-app-transmission=y
# ----------luci-app-watchcat
CONFIG_PACKAGE_luci-app-watchcat=y
# ----------luci-app-v2ray-server
CONFIG_PACKAGE_luci-app-v2ray-server=y
EOF
}

test_content() {
func_content
#=========================================
# 测试域
#=========================================
cat >> .config <<EOF
CONFIG_PACKAGE_e2fsprogs=y
# CONFIG_PACKAGE_luci-app-verysync=y
EOF
}

#↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑上面写配置区块内容↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑
#↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓下面写配置编写逻辑↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓

#=========================================
# 仅选择型号，生成默认配置并保存
#=========================================
# rm -f ./.config*
# cat >> ./.config <<EOF
# CONFIG_TARGET_ramips=y
# CONFIG_TARGET_ramips_mt7621=y
# CONFIG_TARGET_ramips_mt7621_DEVICE_d-team_newifi-d2=y
# EOF
# make defconfig
# mv .config default.config
# echo "Default .config is named to deafult.config"

# 根据输入参数增加内容
if [[ $1 == clean* ]]; then
    echo "生成[洁净]配置"
    clean_content
elif [[ $1 == basic* ]]; then
    echo "生成[基本]配置"
    basic_content
elif [[ $1 == test* ]]; then
    echo "生成[测试]配置"
    test_content
else
    echo "生成[全功能]配置（默认）"
    func_content
fi

# 移除行首的空格和制表符
sed -i 's/^[ \t]*//g' .config
# make defconfig
# diff .config default.config --color
# #diff的返回值1会导致github actions出错，用这个来盖过去
echo "已生成[.config]"
