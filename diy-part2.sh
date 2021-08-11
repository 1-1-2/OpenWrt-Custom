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
CONFIG_USE_MKLIBS=y
EOF
#=========================================
# Remove defaults app
#=========================================
cat >> .config <<EOF
# ----------luci-app-accesscontrol
# CONFIG_PACKAGE_luci-app-accesscontrol is not set
# ----------luci-app-diskman
# CONFIG_PACKAGE_luci-app-diskman_INCLUDE_btrfs_progs is not set
# CONFIG_PACKAGE_luci-app-diskman_INCLUDE_lsblk is not set
# ----------luci-app-passwall - configuration
# CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Dns2socks is not set
# CONFIG_PACKAGE_luci-app-passwall_INCLUDE_PDNSD is not set
# CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Shadowsocks_Libev_Client is not set
# CONFIG_PACKAGE_luci-app-passwall_INCLUDE_ShadowsocksR_Libev_Client is not set
# CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Simple_Obfs is not set
# CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Trojan_Plus is not set
# ----------luci-app-ramfree
# CONFIG_PACKAGE_luci-app-ramfree is not set
# ----------luci-app-rclone
# CONFIG_PACKAGE_luci-app-rclone_INCLUDE_rclone-webui is not set
# CONFIG_PACKAGE_luci-app-rclone_INCLUDE_rclone-ng is not set
# CONFIG_PACKAGE_luci-app-rclone_INCLUDE_fuse-utils is not set
# ----------luci-app-ssr-plus
# CONFIG_PACKAGE_luci-app-ssr-plus is not set
# CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_ShadowsocksR_Libev_Client is not set
EOF
}

basic_content() {
clean_content
#=========================================
# 基础包和应用
#=========================================
cat >> .config <<EOF
CONFIG_PACKAGE_automount=y
CONFIG_PACKAGE_cfdisk=y
CONFIG_PACKAGE_usbutils=y
CONFIG_DEFAULT_kmod-usb3=y
CONFIG_PACKAGE_ipv6helper=y
CONFIG_PACKAGE_coreutils-base64=y
CONFIG_PACKAGE_luci-app-hd-idle=y
CONFIG_PACKAGE_luci-app-cifsd=y
CONFIG_PACKAGE_luci-app-commands=y
CONFIG_PACKAGE_luci-app-qos=y
CONFIG_PACKAGE_luci-app-sqm=y
CONFIG_PACKAGE_luci-app-ttyd=y
CONFIG_PACKAGE_luci-app-wrtbwmon=y
CONFIG_PACKAGE_luci-theme-argon_new=y
EOF
}

func_content() {
basic_content
#=========================================
# 功能包
#=========================================
cat >> .config <<EOF
CONFIG_PACKAGE_luci-app-aria2=y
CONFIG_PACKAGE_luci-app-jd-dailybonus=y
CONFIG_PACKAGE_luci-app-nps=y
CONFIG_PACKAGE_luci-app-openclash=y
CONFIG_PACKAGE_ip6tables-mod-nat=y
CONFIG_PACKAGE_luci-app-transmission=y
CONFIG_PACKAGE_luci-app-unblockmusic_INCLUDE_UnblockNeteaseMusic_Go=y
CONFIG_PACKAGE_luci-app-watchcat=y
CONFIG_PACKAGE_luci-app-zerotier=y
EOF
}

test_content() {
func_content
#=========================================
# 测试域
#=========================================
cat >> .config <<EOF
CONFIG_PACKAGE_luci-app-v2ray-server=y
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

# 删除空行
sed -i 's/^[ \t]*//g' .config
# make defconfig
# diff .config default.config --color
# #diff的返回值1会导致github actions出错，用这个来盖过去
echo "已生成[.config]"
