#!/bin/sh

wait_online() {
  ONLINE_ERR=1

  while [ $ONLINE_ERR -ne 0 ]
  do
    ping -c 1 -W 1 $1 &> /dev/null
    ONLINE_ERR=$?

    if [ $ONLINE_ERR -ne 0 ]
      then
        echo "No internet connection, waiting..."
        sleep 3
    fi
  done

  echo "Internet connection established"
}

_start() {
  . "$(dirname "$0")/conf.sh"

  wait_online ${ENDPOINT_ADDR}

  printf '%s\n' \
  "[Interface]" \
  "PrivateKey = ${PRIVATE_KEY}" \
  "" \
  "[Peer]" \
  "PublicKey = ${ENDPOINT_PUBLIC_KEY}" \
  "AllowedIPs = ${ENDPOINT_ALLOWED_IP}" \
  "Endpoint = ${ENDPOINT_ADDR}:${ENDPOINT_PORT}" \
  "PersistentKeepalive = 20" > "$CFG"

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

  "$(dirname "$0")/traffic_rules.sh" enable

  # Debugging info
  #ping -c3 1.1.1.1
  #ip route show table all
  #ip rule
  #iptables-save

  # Test and revert before permanent deployment
  #sleep 120
  #"$(dirname "$0")/traffic_rules.sh" disable
}

_stop() {
  . "$(dirname "$0")/conf.sh"
  "$(dirname "$0")/traffic_rules.sh" disable

  echo -n "Removing WireGuard interface... "

  ip link set ${IFACE} down
  ip link delete dev ${IFACE}

  echo "done"
}

case "$1" in
  start)
    _start
    ;;

  stop)
    _stop
    ;;

  restart)
    _stop
    _start
    ;;

  *)
    echo "Usage: $0 {start|stop}" >&2
    exit 1
    ;;
esac

exit 0
