# wireguard-ops-scripts

Two small bash scripts for a self-hosted WireGuard server. No dependencies beyond
`wg`, `wg-quick`, `ip` and `awk` (plus `qrencode` if you want a QR code).

| Script | What it does | Where it runs |
|---|---|---|
| `scripts/wg-healthcheck.sh` | Restarts the interface when the most recent handshake of any peer is older than N seconds (default 180), or when the interface is missing. | The side that initiates: a client, a home box behind CGNAT, a site-to-site spoke. |
| `scripts/wg-newpeer.sh` | Generates a key pair and a preshared key, appends the peer to `wg0.conf`, applies it live without dropping the tunnel, writes `clients/<name>.conf` and prints a QR code. | The server, as root. |
| `scripts/wg-healthcheck.cron` | A cron line that runs the health check every two minutes. | Same host as the health check. |

Read both scripts before running them as root. They are short on purpose.

## wg-healthcheck.sh

```bash
sudo cp scripts/wg-healthcheck.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/wg-healthcheck.sh
sudo /usr/local/bin/wg-healthcheck.sh wg0 180
```

Why it exists: a tunnel that sits behind NAT loses its mapping after a few minutes of
silence, and a tunnel whose endpoint changed IP keeps sending to the old address until
something restarts it. `PersistentKeepalive` fixes the first case; nothing in WireGuard
fixes the second, so a cron job does. Background reading:
[WireGuard handshake troubleshooting](https://www.vpnsmith.com/en/blog/wireguard-handshake-troubleshooting-2026),
[PersistentKeepalive explained](https://www.vpnsmith.com/en/blog/wireguard-persistent-keepalive-2026),
[WireGuard behind CGNAT](https://www.vpnsmith.com/en/blog/wireguard-behind-cgnat).

## wg-newpeer.sh

Edit the four variables at the top once (`SERVER_ENDPOINT`, `SERVER_PUBKEY`,
`CLIENT_DNS`, `ALLOWED`), then:

```bash
sudo ./scripts/wg-newpeer.sh phone-eric 10.8.0.5
```

The client file lands in `./clients/phone-eric.conf` with mode 600. Scan the QR code
with the iOS or Android app, or import the file on Windows, macOS or Linux.

## The paid kit these come from

These two scripts ship inside the
[WireGuard Self-Hosting Kit](https://ericgerard.gumroad.com/l/wireguard-kit)
(9 USD), together with a 12-cause troubleshooting checklist, a 21-item hardening
checklist, a cheat sheet (MTU and keepalive tables) and 11 config templates (server,
split tunnel, site-to-site, CGNAT reverse tunnel, wg-easy compose, nftables, sysctl).
The scripts are MIT licensed and free here; the checklists and templates are the paid
part. The kit has not been validated on a multi-device test bench; it condenses the
guides linked above.

The cheat sheet alone is free (pay what you want, 0 USD accepted):
[WireGuard Cheat Sheet](https://ericgerard.gumroad.com/l/wireguard-cheat-sheet?utm_source=github&utm_medium=readme&utm_campaign=wireguard-ops-scripts),
a 4-page PDF with the `wg` / `wg-quick` commands, every `[Interface]` and `[Peer]` key,
the MTU table, port choices and one-line diagnostics.

## License

MIT, see `LICENSE`.
