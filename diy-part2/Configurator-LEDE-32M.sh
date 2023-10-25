#!/bin/bash
#
# Copyright (c) 2022-now 1-1-2 <https://github.com/1-1-2>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# File name: Configurator-OpenWrt-32M.sh
# Description: OpenWrt .config maker script (for addon&paks) for 32MB(256Mb) flash device
#

cat << EOF
=======Configurator-OpenWrt-32M.sh=======
    functions loaded:
        1. add_packages, modification
        2. config_func
        3. config_basic
        4. config_clean
        5. config_test
=========================================
EOF

modification() {
    # 一些可能必要的修改
    echo '[MOD]除去 luci-app-dockerman 的架构限制'
    find -type f -path '*/luci-lib-docker/Makefile' -print -exec sed -i 's#@(aarch64||arm||x86_64)##w /dev/stdout' {} \;
}

add_packages() {
    [ -e is_add_packages ] && echo Add packages is done already. && return 0
    
    # 修改一些依赖
    modification
    
    # 已修改标志（其实也就DEBUG的时候有用）
    touch is_add_packages
}

config_clean() {
    #=========================================
    # Stripping options
    #=========================================
    cat << EOF
CONFIG_STRIP_KERNEL_EXPORTS=y
# CONFIG_USE_MKLIBS is not set
EOF
    #=========================================
    # Remove defaults Apps
    #=========================================
    cat << EOF
# ----------luci-app-ssr-plus
# CONFIG_PACKAGE_luci-app-ssr-plus is not set

EOF
    #=========================================
    # unset some default to avoid duplication
    #=========================================
    cat << EOF
# CONFIG_PACKAGE_luci-app-passwall_Transparent_Proxy is not set
# CONFIG_PACKAGE_luci-app-passwall2_Transparent_Proxy is not set
EOF
}

config_basic() {
    config_clean
    #=========================================
    # 基础包和应用
    #=========================================
    cat << EOF
# ----------extra packages-automount
CONFIG_PACKAGE_automount=y
# ----------extra packages-ipv6helper
CONFIG_PACKAGE_ipv6helper=y
# ----------Utilities-Disc-cfdisk&fdisk
CONFIG_PACKAGE_cfdisk=y
CONFIG_PACKAGE_fdisk=y
# ----------Utilities-Filesystem-e2fsprogs
CONFIG_PACKAGE_e2fsprogs=y
# ----------Utilities-usbutils
CONFIG_PACKAGE_usbutils=y
# ----------Utilities-jq
CONFIG_PACKAGE_jq=y
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
CONFIG_PACKAGE_luci-theme-bootstrap=y
CONFIG_PACKAGE_luci-theme-argonne=y
CONFIG_PACKAGE_luci-app-argonne-config=y
# ----------luci-app-webadmin
CONFIG_PACKAGE_luci-app-webadmin=y
EOF
}

config_func() {
    config_basic
    #=========================================
    # 功能包
    #=========================================
    cat << EOF
# ----------luci-app-aria2
CONFIG_PACKAGE_luci-app-aria2=y
# ----------luci-app-VPNs
CONFIG_PACKAGE_luci-app-nps=y
CONFIG_PACKAGE_luci-app-frpc=y
CONFIG_PACKAGE_luci-app-n2n_v2=y
CONFIG_PACKAGE_luci-app-zerotier=y
# ----------luci-app-openclash
CONFIG_PACKAGE_luci-app-openclash=y
# ----------network-firewall-ip6tables-ip6tables-mod-nat
# CONFIG_PACKAGE_ip6tables-mod-nat=y
# ----------luci-app-transmission
CONFIG_PACKAGE_luci-app-transmission=y
# ----------luci-app-watchcat
CONFIG_PACKAGE_luci-app-watchcat=y
# ----------luci-app-v2ray-server
CONFIG_PACKAGE_luci-app-v2ray-server=y
EOF
}

config_test() {
    config_func
    #=========================================
    # 测试域
    #=========================================
    cat << EOF
# CONFIG_PACKAGE_luci-app-verysync=y
EOF
}

# 移除行首的空格和制表符
sed -i 's/^[ \t]*//g' .config
    
# make defconfig
# diff .config default.config --color
# diff的返回值1会导致github actions出错，用这个来盖过去
echo "=====================已生成 .config 文件，diy-part2.sh 结束====================="
