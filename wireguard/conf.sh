#!/bin/sh

ADDR="10.1.1.2" # Client (our) address in WireGuard network
MASK="24" # WireGuard network mask
PRIVATE_KEY="" # Client (our) private key

ENDPOINT_ADDR="" # WireGuard server address
ENDPOINT_PORT="51820" # WireGuard server port
ENDPOINT_PUBLIC_KEY="" # WireGuard server public key
ENDPOINT_ALLOWED_IP="0.0.0.0/0"

IFACE="wg0"

CFG="/tmp/wireguard_${IFACE}.conf"
