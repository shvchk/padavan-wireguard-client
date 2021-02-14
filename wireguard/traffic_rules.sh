#!/bin/sh

. "$(dirname "$0")/conf.sh"
. "$(dirname "$0")/traffic_rules_remove.sh"

echo -n "Setting up WireGuard traffic rules... "

iptables -I INPUT -i ${IFACE} -j ACCEPT
iptables -t nat -I POSTROUTING -o ${IFACE} -j SNAT --to ${ADDR}

ip route add default dev ${IFACE} table 51
ip rule add to ${ENDPOINT_ADDR} lookup main pref 30
ip rule add to 192.168.1.0/24 lookup main pref 30
ip rule add to all lookup 51 pref 40
ip route flush cache

echo "done"
