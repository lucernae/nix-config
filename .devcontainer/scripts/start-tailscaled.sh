#!/usr/bin/env bash
# start-tailscaled.sh
#
# Starts the Tailscale daemon inside the devcontainer.
# Intended to run as postStartCommand (runs on every container start).
#
# Optional env vars:
#   TAILSCALE_AUTH_KEY — if set, automatically authenticate (no interactive login needed)

set -euo pipefail

log() { echo "[tailscaled] $*"; }

if ! command -v tailscaled &>/dev/null; then
  log "tailscaled not found — skipping."
  exit 0
fi

# Already running?
if sudo tailscale --socket=/var/run/tailscale/tailscaled.sock status &>/dev/null; then
  log "Tailscale already running."
  exit 0
fi

# Ensure state directory exists
sudo mkdir -p /var/lib/tailscale /var/run/tailscale

log "Starting tailscaled..."
sudo tailscaled \
  --state=/var/lib/tailscale/tailscaled.state \
  --socket=/var/run/tailscale/tailscaled.sock \
  --tun=userspace-networking \
  --socks5-server=localhost:1055 \
  --outbound-http-proxy-listen=localhost:1056 \
  &>/tmp/tailscaled.log &

# Wait for the socket to appear
for i in $(seq 1 10); do
  if [ -S /var/run/tailscale/tailscaled.sock ]; then
    break
  fi
  sleep 0.5
done

if [ ! -S /var/run/tailscale/tailscaled.sock ]; then
  log "tailscaled socket did not appear. Check /tmp/tailscaled.log"
  exit 1
fi

# Authenticate
TS_ARGS=(--socket=/var/run/tailscale/tailscaled.sock)
if [ -n "${TAILSCALE_AUTH_KEY:-}" ]; then
  log "Authenticating with auth key..."
  sudo tailscale "${TS_ARGS[@]}" up --authkey="$TAILSCALE_AUTH_KEY" --hostname="devcontainer-$(hostname)"
  log "Tailscale up and authenticated."
else
  log "No TAILSCALE_AUTH_KEY set. Run manually:"
  log "  sudo tailscale --socket=/var/run/tailscale/tailscaled.sock up"
fi
