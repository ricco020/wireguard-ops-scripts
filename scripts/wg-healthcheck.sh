#!/usr/bin/env bash
# wg-healthcheck.sh <interface> [max_age_seconds]
# Restarts the WireGuard interface when the most recent handshake of ANY peer is older
# than max_age (default 180 s), or when no peer has ever completed a handshake.
# Intended for the side that initiates (clients, CGNAT home box, site-to-site spoke).
# Install: cp wg-healthcheck.sh /usr/local/bin/ && chmod +x /usr/local/bin/wg-healthcheck.sh
set -euo pipefail

IFACE="${1:-wg0}"
MAX_AGE="${2:-180}"
NOW=$(date +%s)

if ! ip link show "$IFACE" >/dev/null 2>&1; then
    echo "$(date -Is) $IFACE missing, bringing it up"
    wg-quick up "$IFACE"
    exit 0
fi

# Most recent handshake across all peers (0 if none ever)
LATEST=$(wg show "$IFACE" latest-handshakes | awk '{ if ($2 > m) m = $2 } END { print m + 0 }')
AGE=$(( NOW - LATEST ))

if [ "$LATEST" -eq 0 ] || [ "$AGE" -gt "$MAX_AGE" ]; then
    echo "$(date -Is) $IFACE handshake stale (${AGE}s), restarting"
    wg-quick down "$IFACE" || true
    sleep 2
    wg-quick up "$IFACE"
else
    # Quiet when healthy; uncomment to log every run.
    # echo "$(date -Is) $IFACE ok (${AGE}s)"
    :
fi
