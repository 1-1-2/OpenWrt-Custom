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

    echo
    echo '[FIX] 创建硬链接，解决无法正确识别出简体中文语言包的问题'
    # ref: https://github.com/ysc3839/luci-proto-minieap/pull/2
    find -type d -path '*/po/zh-cn' | xargs dirname | xargs -I'{}' ln -srvn {}/zh-cn {}/zh_Hans

    echo
    echo '[MOD] 更换 luci-app-clash 的依赖 openssl 为 mbedtls'
    find -type f -path '*/luci-app-clash/Makefile' -print -exec sed -i 's/openssl/mbedtls/w /dev/stdout' {} \;

    echo
    echo '[MOD] 更换 luci-app-easymesh 的依赖 openssl 为 mbedtls'
    find -type f -path '*/luci-app-easymesh/Makefile' -print -exec sed -i 's/openssl/mbedtls/w /dev/stdout' {} \;

    echo
    echo '[MOD] 除去 luci-app-dockerman 的架构限制'
    find -type f -path '*/luci-app-dockerman/Makefile' -print -exec sed -i 's#@(aarch64||arm||x86_64)##w /dev/stdout' {} \;
    find -type f -path '*/luci-lib-docker/Makefile' -print -exec sed -i 's#@(aarch64||arm||x86_64)##w /dev/stdout' {} \;

    if [ -e feeds/packages/lang/node/Makefile ]; then
        echo
    	echo '[MOD] 使能 SOFT_FLOAT 环境下的 node'
    	cd feeds/packages/lang/node && pwd -P
        sed -e 's/HAS_FPU/(HAS_FPU||SOFT_FLOAT)/' \
            -e '\#^CONFIGURE_ARGS:= \\#a\	$(if $(findstring mips,$(NODEJS_CPU)), $(if $(CONFIG_SOFT_FLOAT),--with-mips-float-abi=soft)) \\' \
            Makefile > Makefile.mod
        diff -u2 Makefile Makefile.mod
        echo "=====================EOdiff======================="
        mv -f Makefile.mod Makefile
        cd -
    fi
    # echo '[MOD] 把 node 替换成 lean 的'
    # rm -rf feeds/packages/lang/node
    # svn co https://github.com/coolsnowwolf/packages/trunk/lang/node feeds/packages/lang/node
    [ -d feeds/kenzo/upx ] && echo '删除 kenzo 引用的 coolsnowwolf 源的 upx' && rm -vrf feeds/kenzo/upx*

    echo
    echo '[FIX] PKG_USE_MIPS16已被openwrt主线弃用，修改外部包的 PKG_USE_MIPS16:=0 为 PKG_BUILD_FLAGS:=no-mips16'
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
    echo
    echo 'luci-app-vsftpd 定义了一级菜单 <nas>，'
    change_entry services nas feeds/luci/applications/luci-app-ksmbd/root/usr/share/luci/menu.d/luci-app-ksmbd.json
    change_entry services nas feeds/luci/applications/luci-app-hd-idle/root/usr/share/luci/menu.d/luci-app-hd-idle.json
    change_entry services nas feeds/luci/applications/luci-app-aria2/root/usr/share/luci/menu.d/luci-app-aria2.json
    change_entry services nas feeds/luci/applications/luci-app-transmission/root/usr/share/luci/menu.d/luci-app-transmission.json

    echo
    echo 'luci-app-n2n 定义了一级菜单 <VPN>'
    change_entry services vpn feeds/kenzo/luci-app-npc/luasrc/controller/npc.lua
    change_entry services vpn feeds/kenzo/luci-app-udp2raw/files/luci/controller/udp2raw.lua
    change_entry services vpn feeds/luci/applications/luci-app-nps/luasrc/controller/nps.lua
    # change_entry services vpn package/luci-app-kcptun/luasrc/controller/kcptun.lua
    change_entry services vpn package/luci-app-tinyfecvpn/files/luci/controller/tinyfecvpn.lua

    echo
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
    echo '一、向 feeds 里加点东西'
    echo '== 从 lean 那里借个 luci-app-unblockmusic'
    echo -e '备注：\ncoolsnowwolf的unblockmusic支持云解锁、Go和Nodejs\nUnblockNeteaseMusic的luci-app-unblockneteasemusic不支持Go'
    svn co https://github.com/coolsnowwolf/luci/trunk/applications/luci-app-unblockmusic feeds/luci/applications/luci-app-unblockmusic
    # echo '还有依赖 UnblockNeteaseMusic 和 UnblockNeteaseMusic-Go'
    # svn co https://github.com/coolsnowwolf/packages/trunk/multimedia/UnblockNeteaseMusic feeds/packages/multimedia/UnblockNeteaseMusic
    # svn co https://github.com/coolsnowwolf/packages/trunk/multimedia/UnblockNeteaseMusic-Go feeds/packages/multimedia/UnblockNeteaseMusic-Go

    echo '== 从天灵那里借个 luci-app-n2n, luci-app-nps, luci-app-vsftpd'
    svn co https://github.com/immortalwrt/luci/trunk/applications/luci-app-n2n feeds/luci/applications/luci-app-n2n
    svn co https://github.com/immortalwrt/luci/trunk/applications/luci-app-nps feeds/luci/applications/luci-app-nps
    svn co https://github.com/immortalwrt/luci/trunk/applications/luci-app-vsftpd feeds/luci/applications/luci-app-vsftpd
    svn co https://github.com/immortalwrt/luci/trunk/applications/luci-app-speederv2 feeds/luci/applications/luci-app-speederv2
    echo '== 还有依赖 n2n'
    svn co https://github.com/immortalwrt/packages/trunk/net/n2n feeds/packages/net/n2n
    # echo '从 Hyy2001X 那里借一个改好的 luci-app-npc(kenzo中已间接引用)'
    # svn co https://github.com/Hyy2001X/AutoBuild-Packages/trunk/luci-app-npc
    # echo '还有依赖 nps(kenzo中已引用coolsnowwolf源)'
    # svn co https://github.com/immortalwrt/packages/trunk/net/nps feeds/packages/net/nps
    # echo '还有 tinyfecvpn(by Yu Wang)'
    # svn co https://github.com/immortalwrt/packages/trunk/net/tinyfecvpn feeds/packages/net/tinyfecvpn
    echo '== 还有依赖 udp2raw(by Yu Wang)'
    svn co https://github.com/immortalwrt/packages/trunk/net/udp2raw feeds/packages/net/udp2raw

    # M1 END

    # M2 START
    echo '一、向 package 里加点东西'
    cd package

    echo '== 从 lean 那里借一个自动外存挂载 automount'
    svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/automount lean/automount
    sed -i 's/ +ntfs3-mount//w /dev/stdout' lean/automount/Makefile      # 去掉不存在的包

    echo '== 从 lisaac 那里加载 luci-app-diskman'
    wget -nv https://raw.githubusercontent.com/lisaac/luci-app-diskman/master/applications/luci-app-diskman/Makefile -P luci-app-diskman
    
    echo '== 从我的 gist 加载更新的 tinyfecvpn(by Yu Wang)'
    mkdir tinyfecvpn && \
    wget -nv https://gist.githubusercontent.com/1-1-2/4009f064cf994ecbe0b0cf87a2c15599/raw/tinyfecVPN.Makefile -O tinyfecvpn/Makefile
    echo '== 从 douo 那里拉取 tinyfecvpn 的 GUI'
    git clone --depth 1 https://github.com/douo/luci-app-tinyfecvpn.git

    # echo '从 kuoruan 那里拉取 kcptun 的 GUI'
    # git clone --depth 1 https://github.com/kuoruan/luci-app-kcptun.git

    cd ..
    # M2 END

    # 修正依赖，调整菜单
    modification
    echo '=====================修改结束======================='
    echo '[强制] 更新索引，装载软件包'
    ./scripts/feeds update -ifa
    ./scripts/feeds install -a
    echo '=====================装载结束======================='

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
CONFIG_LUCI_LANG_zh_Hans=y
CONFIG_PACKAGE_luci-theme-bootstrap=y
CONFIG_PACKAGE_luci=y
EOF
    #=========================================
    # unset some default to avoid duplication
    #=========================================
    cat >> .config << EOF
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
# ----------Basic_external_drive
CONFIG_PACKAGE_automount=y
CONFIG_PACKAGE_kmod-usb3=y
CONFIG_PACKAGE_luci-app-hd-idle=y
CONFIG_PACKAGE_usbutils=y
# ----------Basic_luci-app-ddns
CONFIG_PACKAGE_ddns-scripts-cloudflare=y
CONFIG_PACKAGE_luci-app-ddns=y
# ----------Basic_luci-cmd
CONFIG_PACKAGE_luci-app-commands=y
CONFIG_PACKAGE_luci-app-ttyd=y
# ----------Basic_small_paks
CONFIG_BUSYBOX_CONFIG_BASE64=y
CONFIG_BUSYBOX_CUSTOM=y
CONFIG_PACKAGE_jq=y
CONFIG_PACKAGE_luci-app-advanced-reboot=y
CONFIG_PACKAGE_luci-app-advanced=y
CONFIG_PACKAGE_luci-app-uhttpd=y
CONFIG_PACKAGE_luci-app-watchcat=y
CONFIG_PACKAGE_luci-app-wifischedule=y
CONFIG_PACKAGE_luci-app-wol=y
# ----------Func_upnp
CONFIG_PACKAGE_luci-app-upnp=y
# ----------STAT_luci-app-statistics
CONFIG_PACKAGE_luci-app-statistics=y
# ----------Utilities_bind
CONFIG_PACKAGE_bind-dig=y
CONFIG_PACKAGE_bind-host=y
# ----------Utilities_e2fsprogs
CONFIG_PACKAGE_e2fsprogs=y
# ----------Utilities_fdisk
CONFIG_PACKAGE_fdisk=y
# ----------Utilities_nettool
CONFIG_PACKAGE_ca-certificates=y
CONFIG_PACKAGE_ethtool=y
CONFIG_PACKAGE_luci-app-iperf3-server=y
CONFIG_PACKAGE_socat=y
# ----------Utilities_parted
CONFIG_PACKAGE_parted=y
# ----------Basic_paks_openwrt
CONFIG_PACKAGE_luci-app-acl=y
CONFIG_PACKAGE_luci-app-ledtrig-rssi=y
CONFIG_PACKAGE_luci-app-ledtrig-switch=y
CONFIG_PACKAGE_luci-app-ledtrig-usbport=y
CONFIG_PACKAGE_luci-proto-wireguard=y
# ----------NAS_luci-app-ksmbd
# CONFIG_PACKAGE_luci-app-samba4 is not set
CONFIG_PACKAGE_luci-app-ksmbd=y
# ----------Theme_argon
CONFIG_PACKAGE_luci-app-argon-config=y
CONFIG_PACKAGE_luci-theme-argon=y
EOF
}

config_func() {
    config_basic
    #=========================================
    # 功能包
    #=========================================
    cat >> .config << EOF
# ----------NAS_luci-app-aria2
CONFIG_PACKAGE_luci-app-aria2=m
# ----------NAS_luci-vsftpd
CONFIG_PACKAGE_luci-app-vsftpd=y
# ----------NET_PACKAGE_kcptun-client
CONFIG_PACKAGE_kcptun-client=m
# ----------PAK_tcpdump-mini
CONFIG_PACKAGE_tcpdump-mini=y
# ----------QOS_luci-app-nft-qos
CONFIG_PACKAGE_luci-app-nft-qos=y
# ----------QOS_luci-sqm
CONFIG_PACKAGE_luci-app-sqm=y
# ----------RPX_n2n
CONFIG_PACKAGE_luci-app-n2n=y
# ----------RPX_nps
CONFIG_PACKAGE_luci-app-npc=m
CONFIG_PACKAGE_luci-app-nps=m
CONFIG_PACKAGE_npc=y
# ----------STAT_luci-app-nlbwmon
CONFIG_PACKAGE_luci-app-nlbwmon=m
# ----------Test_ddns-go
CONFIG_PACKAGE_luci-app-ddns-go=m
# ----------Test_lucky
CONFIG_PACKAGE_luci-app-lucky=m
# ----------Utilities_cfdisk
CONFIG_PACKAGE_cfdisk=y
# ----------rmAD_luci-app-adguardhome
CONFIG_PACKAGE_luci-app-adguardhome=m
# ----------STAT_luci-app-vnstat2
CONFIG_PACKAGE_luci-app-vnstat2=m
# ----------Test_NATMap
CONFIG_PACKAGE_luci-app-natmap=y
# ----------Test_wangyu_UDPspeeder
CONFIG_PACKAGE_UDPspeeder=y
CONFIG_PACKAGE_luci-app-speederv2=y
# ----------Test_wangyu_tinyfecVPN
CONFIG_PACKAGE_luci-app-tinyfecvpn=y
CONFIG_PACKAGE_tinyfecvpn=y
# ----------Test_wangyu_udp2raw
CONFIG_PACKAGE_luci-app-udp2raw=y
CONFIG_PACKAGE_udp2raw=y

EOF
}

config_test() {
    config_func
    #=========================================
    # 测试域
    #=========================================
    cat >> .config << EOF
# ----------Func_luci-app-tinyproxy
CONFIG_PACKAGE_luci-app-tinyproxy=y
# ----------Func_luci-app-wechatpush
CONFIG_PACKAGE_luci-app-wechatpush=y
# ----------Func_unblockmusic_Go
CONFIG_PACKAGE_luci-app-unblockmusic=y
CONFIG_PACKAGE_luci-app-unblockmusic_INCLUDE_UnblockNeteaseMusic_Go=m
# ----------Test_luci-app-store
CONFIG_PACKAGE_luci-app-store=y

EOF
}
