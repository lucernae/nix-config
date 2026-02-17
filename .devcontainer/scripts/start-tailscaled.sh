#!/usr/bin/env bash
# start-tailscaled.sh
#
# Starts the Tailscale daemon inside the devcontainer.
# Intended to run as postStartCommand (runs on every container start).
#
# Follows the official Tailscale Codespace feature conventions:
#   https://github.com/tailscale/codespace
#
# Networking mode (auto-detected):
#   Kernel TUN  — used when /dev/net/tun is available (requires CAP_NET_ADMIN + CAP_MKNOD).
#                 Direct TCP to Tailscale IPs works; MagicDNS works.
#   Userspace   — fallback when TUN device is absent (e.g. restricted Codespace environments).
#                 Connections to Tailscale peers must go via SOCKS5 on localhost:1055.
#
# Optional env vars (set as Codespace secrets):
#   TAILSCALE_AUTH_KEY   — auth key for automatic login
#   TS_AUTH_KEY          — alias used if TAILSCALE_AUTH_KEY is unset

set -euo pipefail

log() { echo "[tailscaled] $*"; }

if ! command -v tailscaled &>/dev/null; then
  log "tailscaled not found — skipping."
  exit 0
fi

TS_SOCKET=/var/run/tailscale/tailscaled.sock

# Already running?
if sudo tailscale --socket="$TS_SOCKET" status &>/dev/null; then
  log "Tailscale already running."
  exit 0
fi

# Ensure state directory exists
sudo mkdir -p /var/lib/tailscale /var/run/tailscale

# Choose networking mode based on TUN device availability.
# The official Tailscale Codespace feature uses kernel TUN when possible
# (requires CAP_NET_ADMIN, CAP_MKNOD, CAP_NET_RAW).
if [ -e /dev/net/tun ]; then
  log "TUN device available — starting tailscaled in kernel TUN mode."
  sudo tailscaled \
    --state=/var/lib/tailscale/tailscaled.state \
    --socket="$TS_SOCKET" \
    &>/tmp/tailscaled.log &
else
  log "TUN device not available — starting tailscaled in userspace networking mode."
  log "Connections to Tailscale peers will go via SOCKS5 on localhost:1055."
  sudo tailscaled \
    --state=/var/lib/tailscale/tailscaled.state \
    --socket="$TS_SOCKET" \
    --tun=userspace-networking \
    --socks5-server=localhost:1055 \
    --outbound-http-proxy-listen=localhost:1056 \
    &>/tmp/tailscaled.log &
fi

# Wait for the socket to appear
for i in $(seq 1 10); do
  if [ -S "$TS_SOCKET" ]; then
    break
  fi
  sleep 0.5
done

if [ ! -S "$TS_SOCKET" ]; then
  log "tailscaled socket did not appear. Check /tmp/tailscaled.log"
  exit 1
fi

# Authenticate.
# TAILSCALE_AUTH_KEY is the Codespace secret name; TS_AUTH_KEY is the official alias.
AUTH_KEY="${TAILSCALE_AUTH_KEY:-${TS_AUTH_KEY:-}}"
TS_ARGS=(--socket="$TS_SOCKET")

if [ -n "$AUTH_KEY" ]; then
  log "Authenticating with auth key..."
  sudo tailscale "${TS_ARGS[@]}" up \
    --accept-routes \
    --authkey="$AUTH_KEY" \
    --hostname="devcontainer-$(hostname)"
  log "Tailscale up and authenticated."
else
  log "No TAILSCALE_AUTH_KEY set. To connect, run:"
  log "  sudo tailscale --socket=$TS_SOCKET up --accept-routes"
fi
