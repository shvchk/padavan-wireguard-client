#!/bin/sh

. "$(dirname "$0")/conf.sh"
. "$(dirname "$0")/traffic_rules_remove.sh"

echo -n "Removing WireGuard interface... "

ip link set ${IFACE} down
ip link delete dev ${IFACE}

echo "done"
