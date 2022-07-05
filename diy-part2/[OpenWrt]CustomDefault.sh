#!/bin/sh
#ref: https://openwrt.org/docs/guide-developer/toolchain/use-buildsystem#custom_files
#ref: https://github.com/coolsnowwolf/lede/blob/master/package/lean/default-settings/files/zzz-default-settings

# 使能自动挂载
uci set fstab.@global[0].anon_mount=1
uci commit fstab

# 更换腾讯源
sed -i 's#downloads.openwrt.org#mirrors.cloud.tencent.com/openwrt#g' /etc/opkg/distfeeds.conf
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

exit 0