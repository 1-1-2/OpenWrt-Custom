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

    echo '[FIX]创建硬链接，解决无法正确识别出简体中文语言包的问题'
    # ref: https://github.com/ysc3839/luci-proto-minieap/pull/2
    find -type d -path '*/po/zh-cn' | xargs dirname | xargs -I'{}' ln -srvn {}/zh-cn {}/zh_Hans

    echo '[MOD]更换 luci-app-clash 的依赖 openssl 为 mbedtls'
    find -type f -path '*/luci-app-clash/Makefile' -print -exec sed -i 's/openssl/mbedtls/w /dev/stdout' {} \;

    echo '[MOD]更换 luci-app-easymesh 的依赖 openssl 为 mbedtls'
    find -type f -path '*/luci-app-easymesh/Makefile' -print -exec sed -i 's/openssl/mbedtls/w /dev/stdout' {} \;

    echo '[MOD]除去 luci-app-dockerman 的架构限制'
    find -type f -path '*/luci-app-dockerman/Makefile' -print -exec sed -i 's#@(aarch64||arm||x86_64)##w /dev/stdout' {} \;
    find -type f -path '*/luci-lib-docker/Makefile' -print -exec sed -i 's#@(aarch64||arm||x86_64)##w /dev/stdout' {} \;

    if [ -e feeds/packages/lang/node/Makefile ]; then
    	echo '[MOD]使能 SOFT_FLOAT 环境下的 node'
    	cd feeds/packages/lang/node
        sed -e 's/HAS_FPU/(HAS_FPU||SOFT_FLOAT)/' \
            -e '\#^CONFIGURE_ARGS:= \\#a\	$(if $(findstring mips,$(NODEJS_CPU)), $(if $(CONFIG_SOFT_FLOAT),--with-mips-float-abi=soft)) \\' \
            Makefile > Makefile.mod
        diff -u2 Makefile Makefile.mod
        echo "=====================EOdiff======================="
        mv -f Makefile.mod Makefile
        cd -
    fi
    # echo '[MOD]把 node 替换成 lean 的'
    # rm -rf feeds/packages/lang/node
    # svn co https://github.com/coolsnowwolf/packages/trunk/lang/node feeds/packages/lang/node

    echo '[FIX]PKG_USE_MIPS16已被openwrt主线弃用，修改外部包的 PKG_USE_MIPS16:=0 为 PKG_BUILD_FLAGS:=no-mips16'
    find -type f -name Makefile -exec sh -c '
        if grep -q "PKG_USE_MIPS16:=0" "$1"; then
            echo -n "[$1] "
            sed -i "s/PKG_USE_MIPS16:=0/PKG_BUILD_FLAGS:=no-mips16/w /dev/stdout" "$1"
        fi
    ' sh {} \;

    # 修改入口
    change_entry() {
        if [ -f "$3" ]; then
            echo "将 $(basename "$3" | cut -d. -f1) 从 $1 移动到 $2" [$3]
            sed -i "s/$1/$2/w /dev/stdout" "$3"
        else
            echo 找不到文件: $3
        fi
    }
    echo 'luci-app-vsftpd 定义了一级菜单 <nas>'
    change_entry services nas feeds/luci/applications/luci-app-ksmbd/root/usr/share/luci/menu.d/luci-app-ksmbd.json
    change_entry services nas feeds/luci/applications/luci-app-hd-idle/root/usr/share/luci/menu.d/luci-app-hd-idle.json
    change_entry services nas feeds/luci/applications/luci-app-aria2/root/usr/share/luci/menu.d/luci-app-aria2.json
    change_entry services nas feeds/luci/applications/luci-app-transmission/root/usr/share/luci/menu.d/luci-app-transmission.json

    echo 'luci-app-n2n 定义了一级菜单 <VPN>'
    change_entry services vpn feeds/kenzo/luci-app-npc/luasrc/controller/npc.lua
    change_entry services vpn feeds/kenzo/luci-app-udp2raw/files/luci/controller/udp2raw.lua
    change_entry services vpn feeds/luci/applications/luci-app-nps/luasrc/controller/nps.lua
    change_entry services vpn package/luci-app-kcptun/luasrc/controller/kcptun.lua
    change_entry services vpn package/luci-app-tinyfecvpn/files/luci/controller/tinyfecvpn.lua

    echo '把 luci-app-nft-qos 从 <services> 搬到 <network>'
    change_entry services network feeds/luci/applications/luci-app-nft-qos/luasrc/controller/nft-qos.lua
    echo "=====================End Of Entry Change======================="
}

add_packages() {
    #=========================================
    # 两种方式（没有本质上的区别）：
    # M1. 从别的(类)OpenWrt源码仓库部分借用，放到feeds文件夹(通常为feeds/luci)
    # M2. 拉取专门的luci包到package文件夹（注意 /package 与 /feeds/packages 的区别）
    # 
    # 注意：加包后，需要创建语言名的硬链接（zh-cn -> zh_Hans），update&install feeds
    #=========================================
    [ -e is_add_packages ] && echo "已进行过加包操作，不再执行" && return 0
    
    # M1 START
    echo '从 lean 那里借个 luci-app-vsftpd'
    svn co https://github.com/coolsnowwolf/luci/trunk/applications/luci-app-vsftpd feeds/luci/applications/luci-app-vsftpd
    echo '还有依赖 vsftpd-alt'
    svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/vsftpd-alt package/lean/vsftpd-alt
    echo '从 lean 那里借个 luci-app-unblockmusic'
    svn co https://github.com/coolsnowwolf/luci/trunk/applications/luci-app-unblockmusic feeds/luci/applications/luci-app-unblockmusic
    echo '还有依赖 UnblockNeteaseMusic 和 UnblockNeteaseMusic-Go'
    svn co https://github.com/coolsnowwolf/packages/trunk/multimedia/UnblockNeteaseMusic feeds/packages/multimedia/UnblockNeteaseMusic
    svn co https://github.com/coolsnowwolf/packages/trunk/multimedia/UnblockNeteaseMusic-Go feeds/packages/multimedia/UnblockNeteaseMusic-Go

    echo '从天灵那里借个 luci-app-nps 和 luci-app-n2n'
    svn co https://github.com/immortalwrt/luci/trunk/applications/luci-app-nps feeds/luci/applications/luci-app-nps
    svn co https://github.com/immortalwrt/luci/trunk/applications/luci-app-n2n feeds/luci/applications/luci-app-n2n
    echo '还有依赖 nps 和 n2n'
    svn co https://github.com/immortalwrt/packages/trunk/net/nps feeds/packages/net/nps
    svn co https://github.com/immortalwrt/packages/trunk/net/n2n feeds/packages/net/n2n
    # echo '还有 tinyfecvpn(by Yu Wang)'
    # svn co https://github.com/immortalwrt/packages/trunk/net/tinyfecvpn feeds/packages/net/tinyfecvpn
    # M1 END

    # M2 START
    cd package

    # echo '从 Hyy2001X 那里借一个改好的 luci-app-npc'
    # svn co https://github.com/Hyy2001X/AutoBuild-Packages/trunk/luci-app-npc

    echo '从 lean 那里借一个自动外存挂载 automount'
    svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/automount lean/automount
    sed -i 's/ +ntfs3-mount//w /dev/stdout' lean/automount/Makefile      # 去掉不存在的包

    echo '从 lisaac 那里加载 luci-app-diskman'
    mkdir -p package/luci-app-diskman && \
    wget https://raw.githubusercontent.com/lisaac/luci-app-diskman/master/applications/luci-app-diskman/Makefile -O luci-app-diskman/Makefile
    mkdir -p package/parted && \
    wget https://raw.githubusercontent.com/lisaac/luci-app-diskman/master/Parted.Makefile -O parted/Makefile
    
    echo '从我的 gist 加载更新的 tinyfecvpn(by Yu Wang)'
    mkdir tinyfecvpn && \
    wget https://gist.githubusercontent.com/1-1-2/4009f064cf994ecbe0b0cf87a2c15599/raw/tinyfecVPN.Makefile -O tinyfecvpn/Makefile
    echo '从 douo 那里拉取 tinyfecvpn 的 GUI'
    git clone --depth 1 https://github.com/douo/luci-app-tinyfecvpn.git

    echo '从 kuoruan 那里拉取 kcptun 的 GUI'
    git clone --depth 1 https://github.com/kuoruan/luci-app-kcptun.git

    cd ..
    # M2 END

    # 修正依赖，调整菜单
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
CONFIG_PACKAGE_ddns-scripts-cloudflare=y
CONFIG_PACKAGE_luci-app-acl=y
CONFIG_PACKAGE_luci-app-advanced=y
CONFIG_PACKAGE_luci-app-ddns=y
CONFIG_PACKAGE_luci-app-ledtrig-rssi=y
CONFIG_PACKAGE_luci-app-ledtrig-switch=y
CONFIG_PACKAGE_luci-app-ledtrig-usbport=y
CONFIG_PACKAGE_luci-app-statistics=y
CONFIG_PACKAGE_luci-app-store=y
CONFIG_PACKAGE_luci-app-upnp=y
CONFIG_PACKAGE_luci-app-wol=y
CONFIG_PACKAGE_luci-proto-wireguard=y
CONFIG_PACKAGE_which=y
# ----------Utilities-network
CONFIG_PACKAGE_bind-dig=y
CONFIG_PACKAGE_bind-host=y
CONFIG_PACKAGE_ca-certificates=y
CONFIG_PACKAGE_ethtool=y
CONFIG_PACKAGE_socat=y
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
# ----------Utilities-json
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
# ----------luci-app-sqm
CONFIG_PACKAGE_luci-app-sqm=y
# ----------luci-app-ttyd
CONFIG_PACKAGE_luci-app-ttyd=y
# ----------luci-app-uhttpd
CONFIG_PACKAGE_luci-app-uhttpd=y
# ----------luci-theme-argon
CONFIG_PACKAGE_luci-app-argon-config=y
CONFIG_PACKAGE_luci-theme-argon=y
CONFIG_PACKAGE_luci-theme-bootstrap=y
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
CONFIG_PACKAGE_luci-app-n2n=y
CONFIG_PACKAGE_luci-app-nps=y
# ----------luci-app-transmission
CONFIG_PACKAGE_luci-app-transmission=y
# ----------luci-app-watchcat
CONFIG_PACKAGE_luci-app-watchcat=y
# ----------Utilities
CONFIG_PACKAGE_iperf3=y
CONFIG_PACKAGE_kcptun-client=y
CONFIG_PACKAGE_tcpdump-mini=y
EOF
}

config_test() {
    config_func
    #=========================================
    # 测试域
    #=========================================
    cat >> .config << EOF
# ----------luci-app-openclash
CONFIG_PACKAGE_luci-app-openclash=y
# ----------network-firewall-ip6tables-ip6tables-mod-nat
# CONFIG_PACKAGE_ip6tables-mod-nat=y

CONFIG_PACKAGE_luci-app-adblock=y
CONFIG_PACKAGE_luci-app-diskman=y
CONFIG_PACKAGE_luci-app-frpc=y
# CONFIG_PACKAGE_luci-app-nlbwmon=y
# CONFIG_PACKAGE_luci-app-tinyproxy=y

CONFIG_PACKAGE_luci-app-unblockmusic=y
# CONFIG_PACKAGE_luci-app-unblockmusic_INCLUDE_UnblockNeteaseMusic_Go=y
# CONFIG_PACKAGE_luci-app-unblockmusic_INCLUDE_UnblockNeteaseMusic_NodeJS is not set

CONFIG_PACKAGE_tinyfecvpn=y
EOF
}
