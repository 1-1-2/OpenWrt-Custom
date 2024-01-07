#!/bin/sh
#ref: https://openwrt.org/docs/guide-developer/toolchain/use-buildsystem#custom_files
#ref: https://github.com/coolsnowwolf/lede/blob/master/package/lean/default-settings/files/zzz-default-settings

# 使能自动挂载
uci set fstab.@global[0].anon_mount=1
uci commit fstab

# 更换腾讯源
sed -i -e 's#downloads.openwrt.org#mirrors.cloud.tencent.com/openwrt#g' -e '/kenzo/d' /etc/opkg/distfeeds.conf
# 修改默认密码为password
# sed -i 's/root::0:0:99999:7:::/root:$1$V4UetPzk$CYXluq4wUazHjmCDBCqXF.:0:0:99999:7:::/g' /etc/shadow

# redirect ipv6 dns
# sed -i '/REDIRECT --to-ports 53/d' /etc/firewall.user
# echo 'iptables -t nat -A PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 53' >> /etc/firewall.user
# echo 'iptables -t nat -A PREROUTING -p tcp --dport 53 -j REDIRECT --to-ports 53' >> /etc/firewall.user
# echo '[ -n "$(command -v ip6tables)" ] && ip6tables -t nat -A PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 53' >> /etc/firewall.user
# echo '[ -n "$(command -v ip6tables)" ] && ip6tables -t nat -A PREROUTING -p tcp --dport 53 -j REDIRECT --to-ports 53' >> /etc/firewall.user

# sed -i '/option disabled/d' /etc/config/wireless
# sed -i '/set wireless.radio${devidx}.disabled/d' /lib/wifi/mac80211.sh

echo 'hsts=0' > /root/.wgetrc
[ -d /mnt/mmcblk0/ ] && [ ! -e /root/emmc ] && ln -s /mnt/mmcblk0 /root/emmc
# echo '/root' > /lib/upgrade/keep.d/home

# 为硬件NAT添加一个基于MAC的exclude
grep -q 'offload_exclude' /etc/config/firewall || cat >> /etc/config/firewall << EOF
config ipset
	option name 'offload_exclude'
	option family 'ipv4'
	option comment '绕过HWNAT的设备MAC'
	list match 'mac'
EOF
mkdir -p /overlay/upper/usr/share/firewall4/templates
sed 's/\t\tmeta l4proto { tcp, udp } flow offload @ft;/{% if (fw4.default_option("flow_offloading_hw")): %}\n\t\tether saddr != @offload_exclude meta l4proto { tcp, udp } flow offload @ft comment "!fw4: Offload with exclude"\n{% endif %}\n{% if (!fw4.default_option("flow_offloading_hw")): %}\n\t\tmeta l4proto { tcp, udp } flow offload @ft comment "!fw4: Offload with no exclude"\n{% endif %}/' /rom/usr/share/firewall4/templates/ruleset.uc > /overlay/upper/usr/share/firewall4/templates/ruleset.uc

exit 0