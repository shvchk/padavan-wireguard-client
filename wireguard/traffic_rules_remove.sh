#!/bin/sh

. "$(dirname "$0")/conf.sh"

echo -n "Removing WireGuard traffic rules... "

iptables -D INPUT -i ${IFACE} -j ACCEPT
iptables -t nat -D POSTROUTING -o ${IFACE} -j SNAT --to ${ADDR}

ip route del default dev ${IFACE} table 51
ip rule del to ${ENDPOINT_ADDR} lookup main pref 30
ip rule del to 192.168.1.0/24 lookup main pref 30
ip rule del to all lookup 51 pref 40
ip route flush cache

echo "done"
