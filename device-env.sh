#!/bin/bash

echo "Hi, I'm $0."
case $1 in
    1)
        DEVICE_TAG="Lean's LEDE - HC5661"
        REPO_USE=coolsnowwolf/lede
        REPO_BRANCH=master
#         COMMIT_SHA=latest
        DIY_P2_SH="diy-part2/[Lean's LEDE]HC5661-part2.sh"
        DEPENDS=$(curl -fsSL "https://gist.githubusercontent.com/1-1-2/38e424cd9da729f72fa4a495d23271ea/raw/lean's%2520lede")
        SEQ_FILE="testSeq/lean's lede.ini"
        ;;
    2)
        DEVICE_TAG="Lean's LEDE - Newifi3_D2"
        REPO_USE=coolsnowwolf/lede
        REPO_BRANCH=master
#         COMMIT_SHA=latest
        DIY_P2_SH="diy-part2/[Lean's LEDE]Newifi3D2-part2.sh"
        DEPENDS=$(curl -fsSL "https://gist.githubusercontent.com/1-1-2/38e424cd9da729f72fa4a495d23271ea/raw/lean's%2520lede")
        SEQ_FILE="testSeq/lean's lede.ini"
        ;;
    3)
        DEVICE_TAG="Lean's LEDE - RE-SP-01B"
        REPO_USE=coolsnowwolf/lede
        REPO_BRANCH=master
#         COMMIT_SHA=latest
        DIY_P2_SH="diy-part2/[Lean's LEDE]RE-SP-01B-part2.sh"
        DEPENDS=$(curl -fsSL "https://gist.githubusercontent.com/1-1-2/38e424cd9da729f72fa4a495d23271ea/raw/lean's%2520lede")
        SEQ_FILE="testSeq/lean's lede.ini"
        ;;
    4)
        DEVICE_TAG="OpenWrt - Newifi3_D2"
        REPO_USE=openwrt/openwrt
        REPO_BRANCH=master
#         COMMIT_SHA=latest
        DIY_P2_SH="diy-part2/[OpenWrt]Newifi3D2-part2.sh"
        DEPENDS=$(curl -fsSL "https://gist.githubusercontent.com/1-1-2/38e424cd9da729f72fa4a495d23271ea/raw/openwrt")
        SEQ_FILE="testSeq/openwrt.ini"
        ;;
    5)
        DEVICE_TAG="OpenWrt - RE-SP-01B"
        REPO_USE=openwrt/openwrt
        REPO_BRANCH=master
#         COMMIT_SHA=latest
        DIY_P2_SH="diy-part2/[OpenWrt]RE-SP-01B-part2.sh"
        DEPENDS=$(curl -fsSL "https://gist.githubusercontent.com/1-1-2/38e424cd9da729f72fa4a495d23271ea/raw/openwrt")
        SEQ_FILE="testSeq/openwrt.ini"
        ;;
    6)
        # undefined
        ;;
    7)
        # undefined
        ;;
    *)
        echo "input error"
        exit 1
esac

# 检查是否已经指定 COMMIT_SHA 了
if [ $COMMIT_SHA == 'latest' ]; then
    USE_COMMIT_SHA='latest'
else
    USE_COMMIT_SHA=$COMMIT_SHA
fi

# set ENVs
cat << EOF | tee -a $GITHUB_ENV
DEVICE_TAG=${DEVICE_TAG}
REPO_USE=${REPO_USE}
REPO_BRANCH=${REPO_BRANCH}
USE_COMMIT_SHA=${USE_COMMIT_SHA}
DIY_P2_SH=${DIY_P2_SH}
DEPENDS=${DEPENDS}
SEQ_FILE=${SEQ_FILE}

EOF
