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

get_wan_prefix() {
  wan="$(nvram get wan_ifname)"
  prefix="$(ip addr show "$wan" | grep -E '^ +inet' | awk '{print $2}')"

  echo "$prefix"
}

traffic_rules() {
  . "$(dirname "$0")/conf.sh"

  case "$1" in
    enable)
      ip_action="add"
      iptables_action="-I"
      echo -n "Setting up WireGuard traffic rules... "
      ;;

    disable)
      ip_action="del"
      iptables_action="-D"
      echo -n "Removing WireGuard traffic rules... "
      ;;

    *)
      echo "Wrong argument: 'enable' or 'disable' expected. Doing nothing." >&2
      return
      ;;
  esac

  iptables $iptables_action INPUT -i $IFACE -j ACCEPT
  iptables -t nat $iptables_action POSTROUTING -o $IFACE -j SNAT --to $ADDR
  iptables -t mangle $iptables_action POSTROUTING -o $IFACE -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu

  ip route $ip_action default dev $IFACE table 51
  ip rule $ip_action to $ENDPOINT_ADDR table main pref 30
  ip rule $ip_action to $(get_lan_prefix) table main pref 30

  wan_prefix=$(get_wan_prefix)

  if [ -n "$wan_prefix" ]; then
    ip rule $ip_action to $wan_prefix table main pref 30
  fi

  ip rule $ip_action to all table 51 pref 40
  ip route flush cache
  echo "done"
}

case "$1" in
  enable)
    traffic_rules disable 2> /dev/null
    traffic_rules enable
    ;;

  disable)
    traffic_rules disable
    ;;

  *)
    echo "Usage: $0 {enable|disable}" >&2
    exit 1
    ;;
esac

exit 0
