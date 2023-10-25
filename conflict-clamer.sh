#!/bin/bash

# 解决dnsmasq冲突
if grep -q "CONFIG_PACKAGE_dnsmasq-full=y" .config ; then
    sed -i -e '/CONFIG_PACKAGE_dnsmasq=y/d' -e '/CONFIG_PACKAGE_dnsmasq-full=y/a\# CONFIG_PACKAGE_dnsmasq is not set' .config
    echo '[解决冲突]dnsmasq-full与dnsmasq不能共存，将只保留dnsmasq-full'
fi
