#!/bin/sh

. "$(dirname "$0")/conf.sh"
. "$(dirname "$0")/../online_wait.sh" ${ENDPOINT_ADDR}

cat << CFG > "$CFG"
[Interface]
PrivateKey = ${PRIVATE_KEY}

[Peer]
PublicKey = ${ENDPOINT_PUBLIC_KEY}
AllowedIPs = ${ENDPOINT_ALLOWED_IP}
Endpoint = ${ENDPOINT_ADDR}:${ENDPOINT_PORT}
PersistentKeepalive = 20
CFG

#cat "$CFG"

echo -n "Setting up WireGuard interface... "

[ -e /sys/module/wireguard ] `modprobe wireguard`

! (ip link show ${IFACE} 2>/dev/null) && \
  (ip link add dev ${IFACE} type wireguard) && \
  (ip addr add ${ADDR}/${MASK} dev ${IFACE}) && \
  (wg setconf ${IFACE} "$CFG") && \
  (sleep 1) && \
  (ip link set ${IFACE} up)

echo "done"

rm -f "$CFG"

echo 1 > /proc/sys/net/ipv4/ip_forward
echo 0 > /proc/sys/net/ipv4/conf/all/accept_redirects
echo 0 > /proc/sys/net/ipv4/conf/all/send_redirects

. "$(dirname "$0")/traffic_rules.sh"

# Debugging info
#ping -c3 1.1.1.1
#ip route show table all
#ip rule
#iptables-save

# Test and revert before permanent deployment
#sleep 120
#. "$(dirname "$0")/traffic_rules_remove.sh"
