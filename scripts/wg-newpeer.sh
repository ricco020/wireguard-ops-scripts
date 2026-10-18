#!/usr/bin/env bash
# wg-newpeer.sh <name> <tunnel_ip>   e.g.  wg-newpeer.sh phone-eric 10.8.0.5
# Run on the server as root. Generates a key pair + PSK, appends the peer to wg0.conf,
# applies it live (no tunnel drop), writes the client config to ./clients/<name>.conf
# and prints a QR code if qrencode is installed.
# Edit the four variables below once.
set -euo pipefail

SERVER_ENDPOINT="SERVER_PUBLIC_IP:SERVER_PORT"
SERVER_PUBKEY="SERVER_PUBKEY"
CLIENT_DNS="1.1.1.1"
ALLOWED="0.0.0.0/0, ::/0"      # full tunnel; use "10.8.0.0/24, 192.168.1.0/24" for split
IFACE="wg0"
CONF="/etc/wireguard/${IFACE}.conf"

NAME="${1:?name}"
IP="${2:?tunnel ip, e.g. 10.8.0.5}"

umask 077
mkdir -p clients
PRIV=$(wg genkey)
PUB=$(echo "$PRIV" | wg pubkey)
PSK=$(wg genpsk)

cat >> "$CONF" <<PEER

[Peer]
# $NAME  (added $(date +%F))
PublicKey = $PUB
PresharedKey = $PSK
AllowedIPs = ${IP}/32
PEER

wg syncconf "$IFACE" <(wg-quick strip "$IFACE")

cat > "clients/${NAME}.conf" <<CLIENT
[Interface]
PrivateKey = $PRIV
Address = ${IP}/32
DNS = $CLIENT_DNS

[Peer]
PublicKey = $SERVER_PUBKEY
PresharedKey = $PSK
Endpoint = $SERVER_ENDPOINT
AllowedIPs = $ALLOWED
PersistentKeepalive = 25
CLIENT

echo "Peer $NAME ($IP) added. Client config: clients/${NAME}.conf"
if command -v qrencode >/dev/null; then
    qrencode -t ansiutf8 < "clients/${NAME}.conf"
else
    echo "(install qrencode to print a QR code for the mobile app)"
fi
