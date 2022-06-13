#!/bin/sh
set -euo pipefail

log="logger -t wireguard"

dir="$(cd -- "$(dirname "$0")" &> /dev/null && pwd)"
config_file="$(ls -v "${dir}"/*conf | head -1)"
iface="$(basename "$config_file" .conf)"
wan="$(ip route | grep 'default via' | head -1 | awk '{print $5}')"
wan_mtu="$(cat /sys/class/net/${wan}/mtu)"
mtu=$(( wan_mtu > 0 ? wan_mtu - 80 : 1500 - 80 ))
fwmark=51820
routes_table=$fwmark

filtered_config=""
filtered_config_file="/tmp/wireguard.${iface}.filtered.conf"
client_addr=""
client_mask=""
server_addr=""
server_port=""
allowed_ips=""

die() {
  $log "${1}. Exit."
  exit 1
}

wait_online() {
  local i=0
  until ping -c 1 -W 1 $1 &> /dev/null; do
    i=$(( i < 300 ? i + 1 : i ))
    $log "No ping response from $1, waiting $i sec..."
    sleep $i
  done
}

validate_iface_name() {
  [ -z "$(echo "$1" | sed -E 's/^[a-zA-Z0-9_=+.-]{1,15}//')" ] || return 1
}

# Dumb filter for IPv4 or FQDN addresses (has dot),
# since we don't support IPv6 yet
get_valid_addrs() {
  addrs="$(echo "$1" | sed 's/,/ /g')"
  for addr in $addrs; do
    if echo "$addr" | grep -q '\.'; then
      echo -n "$addr "
    fi
  done
}

# Collapse spaces, trim leading and trailing spaces
trim_spaces() {
  echo "$1" | sed -E 's/ +/ /g;s/^ //;s/ $//'
}

add_to_filtered_config() {
  filtered_config="${filtered_config}${1}"$'\n'
}

parse_config() {
  $log "Parsing config"
  dos2unix -u "$1"
  local line key val addr cidr err

  while read -r line || [ -n "$line" ]; do
    [ -z "$line" ] ||
    [ "${line:0:1}" = "#" ] && continue

    line="$(echo "$line" | sed 's/ //g')"
    key="$(echo "$line" | cut -d '=' -f 1)"
    val="$(echo "$line" | cut -d '=' -f 2-)"

    case "$key" in
      Address)
        [ -n "$client_addr" ] && continue
        cidr="$(get_valid_addrs "$val" | cut -d ' ' -f 1)"
        client_addr="$(echo "$cidr" | cut -d '/' -f 1)"
        client_mask="$(echo "$cidr" | cut -d '/' -f 2)"
        [ "$client_addr" = "$client_mask" ] && client_mask="32"
        ;;

      Endpoint)
        [ -n "$server_addr" ] && continue
        addr="$(get_valid_addrs "$val" | cut -d ' ' -f 1)"
        server_addr="$(echo "$addr" | cut -d ':' -f 1)"
        server_port="$(echo "$addr" | cut -d ':' -f 2)"
        add_to_filtered_config "${key}=${server_addr}:${server_port}"
        ;;

      AllowedIPs)
        allowed_ips="$allowed_ips $(get_valid_addrs "$val")"
        ;;

      [*|PrivateKey|PublicKey|PresharedKey|PersistentKeepalive)
        add_to_filtered_config "$line"
        ;;

      *)
        $log "Ignoring config entry: $key"
        continue
        ;;
    esac
  done < "$1"

  allowed_ips="$(trim_spaces "$allowed_ips")"
  add_to_filtered_config "AllowedIPs=$(echo "$allowed_ips" | sed 's/ /,/g')"

  err=""
  [ -z "$client_addr" ] && err="No valid client address in config file"
  [ -z "$server_addr" ] && err="No valid server address in config file"
  [ -z "$allowed_ips" ] && err="No valid allowed IPs in config file"
  [ -n "$err" ] && die "$err"

  if [ "$1" = "$config_file" ]; then
    echo "$filtered_config" > "$filtered_config_file"
  fi
}

configure_traffic_rules() {
  [ -n "$client_addr" ] || parse_config "$config"
  local action def_route

  def_route=0
  echo "$allowed_ips" | grep -q '/0' && def_route=1

  case "$1" in
    enable)
      action="-I"
      $log "Setting up WireGuard traffic rules..."

      ip route add default dev $iface table $routes_table

      if [ $def_route = 1 ]; then
        wg set $iface fwmark $fwmark
        ip rule add not fwmark $fwmark table $routes_table
        ip rule add table main suppress_prefixlength 0
        sysctl -q net.ipv4.conf.all.src_valid_mark=1
      else
        for i in $allowed_ips; do
          ip rule add to $i table $routes_table pref 5000
        done
      fi
      ;;

    disable)
      action="-D"
      ip rule del table $routes_table
      ip rule del table main suppress_prefixlength 0
      $log "Removing WireGuard traffic rules... "
      ;;

    *)
      $log "Wrong argument: 'enable' or 'disable' expected. Doing nothing." >&2
      return
      ;;
  esac

  if [ $def_route = 1 ]; then
    #iptables $action PREROUTING ! -i $iface -d $client_addr -m addrtype ! --src-type LOCAL -j DROP
    iptables -t mangle $action POSTROUTING -m mark --mark $fwmark -p udp -j CONNMARK --save-mark
    iptables -t mangle $action PREROUTING -p udp -j CONNMARK --restore-mark
  fi

  iptables -t nat $action POSTROUTING -o $iface -j SNAT --to $client_addr
  iptables -t mangle $action FORWARD ! -o br0 -p tcp -m tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu
}

start() {
  $log "Starting"
  ip link show dev "$iface" &> /dev/null && die "'$iface' already exists"
  validate_iface_name "$iface" || die "Invalid interface name"
  parse_config "$config_file"

  $log "Setting up interface"
  modprobe wireguard
  ip link add $iface type wireguard
  ip addr add $client_addr/$client_mask dev $iface
  wg setconf $iface "$filtered_config_file"
  ip link set $iface up mtu $mtu

  configure_traffic_rules enable
}

stop() {
  rmmod wireguard &> /dev/null
  configure_traffic_rules disable
}

case "$1" in
  start)
    start
    ;;

  stop)
    stop
    ;;

  restart)
    stop
    start
    ;;

  traffic-rules)
    configure_traffic_rules "$2"
    ;;

  *)
    echo "Usage: $0 {start|stop}" >&2
    exit 1
    ;;
esac

exit 0
