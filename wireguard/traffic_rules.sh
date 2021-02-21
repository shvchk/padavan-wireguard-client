#!/bin/sh

mask2cidr() {
  b=0
  IFS=.
  for dec in $1 ; do
    case $dec in
      255) b=$((b+8));;
      254) b=$((b+7));;
      252) b=$((b+6));;
      248) b=$((b+5));;
      240) b=$((b+4));;
      224) b=$((b+3));;
      192) b=$((b+2));;
      128) b=$((b+1));;
      0);;
      *) echo "Error: $dec is not recognized"; exit 1
    esac
  done
  echo "$b"
}

get_lan_prefix() {
  ip="$(nvram get lan_ipaddr | sed 's/ *//g')"
  mask="$(nvram get lan_netmask | sed 's/ *//g')"
  len="$(mask2cidr "${mask}")"

  echo "${ip}/${len}"
}

_enable() {
  . "$(dirname "$0")/conf.sh"
  
  _disable 2> /dev/null

  echo -n "Setting up WireGuard traffic rules... "

  iptables -I INPUT -i ${IFACE} -j ACCEPT
  iptables -t nat -I POSTROUTING -o ${IFACE} -j SNAT --to ${ADDR}
  iptables -t mangle -I POSTROUTING -o ${IFACE} -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu

  ip route add default dev ${IFACE} table 51
  ip rule add to ${ENDPOINT_ADDR} lookup main pref 30
  ip rule add to $(get_lan_prefix) lookup main pref 30
  ip rule add to all lookup 51 pref 40
  ip route flush cache

  echo "done"
}

_disable() {
  . "$(dirname "$0")/conf.sh"

  echo -n "Removing WireGuard traffic rules... "

  iptables -D INPUT -i ${IFACE} -j ACCEPT
  iptables -t nat -D POSTROUTING -o ${IFACE} -j SNAT --to ${ADDR}

  ip route del default dev ${IFACE} table 51
  ip rule del to ${ENDPOINT_ADDR} lookup main pref 30
  ip rule del to $(get_lan_prefix) lookup main pref 30
  ip rule del to all lookup 51 pref 40
  ip route flush cache

  echo "done"
}

case "$1" in
  enable)
    _enable
    ;;

  disable)
    _disable
    ;;

  *)
    echo "Usage: $0 {enable|disable}" >&2
    exit 1
    ;;
esac

exit 0
