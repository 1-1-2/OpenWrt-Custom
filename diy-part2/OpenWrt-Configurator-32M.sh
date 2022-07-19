#!/bin/bash
#
# Copyright (c) 2022-now 1-1-2 <https://github.com/1-1-2>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# File name: OpenWrt-Configurator-32M.sh
# Description: OpenWrt .config maker script (for addon&paks) for 32MB(256Mb) flash device
#

cat << EOF
=======OpenWrt-Configurator-32M.sh=======
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
    echo '[MOD]更换 luci-app-clash 的依赖 openssl 为 wolfssl'
    find -type f -path '*/luci-app-clash/Makefile' -print -exec sed -i 's/openssl/wolfssl/w /dev/stdout' {} \;

    echo '[MOD]更换 luci-app-easymesh 的依赖 openssl 为 wolfssl'
    find -type f -path '*/luci-app-easymesh/Makefile' -print -exec sed -i 's/openssl/wolfssl/w /dev/stdout' {} \;

    echo '[MOD]除去 luci-app-dockerman 的架构限制'
    find -type f -path '*/luci-app-dockerman/Makefile' -print -exec sed -i 's#@(aarch64||arm||x86_64)##w /dev/stdout' {} \;
    find -type f -path '*/luci-lib-docker/Makefile' -print -exec sed -i 's#@(aarch64||arm||x86_64)##w /dev/stdout' {} \;

    echo '[MOD]使能 SOFT_FLOAT 环境下的 node'
    [ -e feeds/packages/lang/node/Makefile ] && sed -i 's/HAS_FPU/(HAS_FPU||SOFT_FLOAT)/w /dev/stdout' feeds/packages/lang/node/Makefile
}

add_packages(){
    #=========================================
    # 两种方式（没有本质上的区别）：
    # M1. 从别的(类)OpenWrt源码仓库部分借用，放到feeds文件夹(通常为feeds/luci)
    # M2. 拉取专门的luci包到package文件夹（注意 /package 与 /feeds/packages 的区别）
    # M3. 修正语言名（zh-cn -> zh_Hans），更新feeds索引，安装feeds
    #=========================================
    [ -e is_add_packages ] && echo Add packages is done already. && return 0
    
    # M1
    echo '从 lean 那里借个 luci-app-vsftpd'
    svn co https://github.com/coolsnowwolf/luci/trunk/applications/luci-app-vsftpd feeds/luci/applications/luci-app-vsftpd
    echo '还有依赖 vsftpd-alt'
    svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/vsftpd-alt package/lean/vsftpd-alt
    echo '从 lean 那里借个 luci-app-unblockmusic'
    svn co https://github.com/coolsnowwolf/luci/trunk/applications/luci-app-unblockmusic feeds/luci/applications/luci-app-unblockmusic
    echo '还有依赖 UnblockNeteaseMusic 和 UnblockNeteaseMusic-Go'
    svn co https://github.com/coolsnowwolf/packages/trunk/multimedia/UnblockNeteaseMusic feeds/packages/multimedia/UnblockNeteaseMusic
    svn co https://github.com/coolsnowwolf/packages/trunk/multimedia/UnblockNeteaseMusic-Go feeds/packages/multimedia/UnblockNeteaseMusic-Go

    echo '从天灵那里借个 luci-app-nps'
    svn co https://github.com/immortalwrt/luci/trunk/applications/luci-app-nps feeds/luci/applications/luci-app-nps
    echo '还有依赖 nps'
    svn co https://github.com/immortalwrt/packages/trunk/net/nps feeds/packages/net/nps

    exist_sed(){
        if [ -f "$1" ]; then
            cp -f "$1" tmp/exist_sed.before
            sed -i 's/services/nas/' "$1"
            echo "将 $(basename "$1" | cut -d. -f1) 从 services 移动到 nas" [$1]
            diff tmp/exist_sed.before "$1"
            echo "=====================EOF======================="
        else
            echo 没找到$1
        fi
    }
    echo 'luci-app-vsftpd 定义了一级菜单 <nas>，顺便修改一些菜单入口到该菜单'
    exist_sed feeds/luci/applications/luci-app-ksmbd/root/usr/share/luci/menu.d/luci-app-ksmbd.json
    exist_sed feeds/luci/applications/luci-app-hd-idle/root/usr/share/luci/menu.d/luci-app-hd-idle.json
    exist_sed feeds/luci/applications/luci-app-aria2/root/usr/share/luci/menu.d/luci-app-aria2.json
    exist_sed feeds/luci/applications/luci-app-transmission/root/usr/share/luci/menu.d/luci-app-transmission.json

    # M2
    cd package

    # echo '从 Hyy2001X 那里借一个改好的 luci-app-npc'
    # svn co https://github.com/Hyy2001X/AutoBuild-Packages/trunk/luci-app-npc

    echo '从 lean 那里借一个自动外存挂载 automount'
    svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/automount lean/automount
    sed -i 's/ +ntfs3-mount//w /dev/stdout' lean/automount/Makefile      # 去掉不存在的包

    cd ..

    # 解决无法正确识别出简体中文语言包的问题
    # ref: https://github.com/ysc3839/luci-proto-minieap/pull/2
    find -type d -path '*/po/zh-cn' | xargs dirname | xargs -I'{}' ln -srvn {}/zh-cn {}/zh_Hans

    # 修改一些依赖
    modification
    # 最后[强制]更新一下索引和安装一下包
    ./scripts/feeds update -ifa
    ./scripts/feeds install -a

    # 已修改标志（其实也就DEBUG的时候有用）
    touch is_add_packages
}

config_clean() {
    #=========================================
    # Stripping options
    #=========================================
    cat >> .config << EOF
CONFIG_STRIP_KERNEL_EXPORTS=y
# CONFIG_USE_MKLIBS is not set
EOF
    #=========================================
    # Luci
    #=========================================
    cat >> .config << EOF
CONFIG_PACKAGE_luci=y
CONFIG_LUCI_LANG_zh_Hans=y
EOF
    #=========================================
    # unset some default to avoid duplication
    #=========================================
    cat >> .config << EOF
# CONFIG_PACKAGE_luci-app-passwall_Transparent_Proxy is not set
# CONFIG_PACKAGE_luci-app-passwall2_Transparent_Proxy is not set
EOF
    #=========================================
    # use dnsmasq-full as default instead of
    # dnsmasq to avoid potential conflicts
    #=========================================
    cat >> .config << EOF
# CONFIG_PACKAGE_dnsmasq is not set
CONFIG_PACKAGE_dnsmasq-full=y
EOF
}

config_basic() {
    config_clean
    #=========================================
    # 基础包和应用
    #=========================================
    cat >> .config << EOF
# ----------select for openwrt
CONFIG_PACKAGE_luci-app-acl=y
CONFIG_PACKAGE_luci-app-advanced=y
CONFIG_PACKAGE_luci-app-ddns=y
CONFIG_PACKAGE_luci-app-statistics=y
CONFIG_PACKAGE_luci-app-nlbwmon=y
CONFIG_PACKAGE_luci-app-store=y
CONFIG_PACKAGE_luci-app-upnp=y
CONFIG_PACKAGE_luci-app-wol=y
# ----------automount from lean
CONFIG_PACKAGE_automount=y
CONFIG_PACKAGE_block-mount=y
CONFIG_PACKAGE_kmod-fs-ext4=y
CONFIG_PACKAGE_kmod-fs-exfat=y
CONFIG_PACKAGE_kmod-fs-ntfs=y
# ----------Utilities-usbutils
CONFIG_PACKAGE_usbutils=y
# ----------Kernel modules-USB Support-kmod-usb3
CONFIG_DEFAULT_kmod-usb3=y
# ----------Utilities-Disc-cfdisk&fdisk
CONFIG_PACKAGE_cfdisk=y
CONFIG_PACKAGE_fdisk=y
# ----------Utilities-Filesystem-e2fsprogs
CONFIG_PACKAGE_e2fsprogs=y
# ----------luci-app-hd-idle
CONFIG_PACKAGE_luci-app-hd-idle=y
# ----------Utilities-jq
CONFIG_PACKAGE_jq=y
# ----------Utilities-coreutils-base64
CONFIG_PACKAGE_coreutils-base64=y
# ----------luci-app-ksmbd
CONFIG_PACKAGE_luci-app-ksmbd=y
# ----------luci-app-commands
CONFIG_PACKAGE_luci-app-commands=y
# ----------luci-app-qos
CONFIG_PACKAGE_luci-app-qos=y
# ----------luci-app-nft-qos
CONFIG_PACKAGE_luci-app-nft-qos=y
# ----------luci-app-eqos
CONFIG_PACKAGE_luci-app-eqos=y
# ----------luci-app-sqm
CONFIG_PACKAGE_luci-app-sqm=y
# ----------luci-app-ttyd
CONFIG_PACKAGE_luci-app-ttyd=y
# ----------luci-theme-argon
CONFIG_PACKAGE_luci-theme-bootstrap=y
CONFIG_PACKAGE_luci-theme-argon=y
CONFIG_PACKAGE_luci-app-argon-config=y
EOF
}

config_func() {
    config_basic
    #=========================================
    # 功能包
    #=========================================
    cat >> .config << EOF
# ----------luci-app-vsftpd
CONFIG_PACKAGE_luci-app-vsftpd=y
# ----------luci-app-aria2
CONFIG_PACKAGE_luci-app-aria2=y
# ----------luci-app-VPNs
CONFIG_PACKAGE_luci-app-nps=y
CONFIG_PACKAGE_luci-app-frpc=y
# ----------luci-app-openclash
CONFIG_PACKAGE_luci-app-openclash=y
# ----------network-firewall-ip6tables-ip6tables-mod-nat
# CONFIG_PACKAGE_ip6tables-mod-nat=y
# ----------luci-app-transmission
CONFIG_PACKAGE_luci-app-transmission=y
# ----------luci-app-watchcat
CONFIG_PACKAGE_luci-app-watchcat=y
EOF
}

config_test() {
    config_func
    #=========================================
    # 测试域
    #=========================================
    cat >> .config << EOF
CONFIG_PACKAGE_luci-app-ledtrig-rssi=y
CONFIG_PACKAGE_luci-app-ledtrig-switch=y
CONFIG_PACKAGE_luci-app-ledtrig-usbport=y
CONFIG_PACKAGE_luci-app-uhttpd=y
CONFIG_PACKAGE_luci-app-unblockmusic=y
CONFIG_PACKAGE_luci-app-adblock=y
CONFIG_PACKAGE_luci-app-tinyproxy=y
CONFIG_PACKAGE_luci-app-wireguard=y
CONFIG_PACKAGE_tcpdump-mini=y
EOF
}
