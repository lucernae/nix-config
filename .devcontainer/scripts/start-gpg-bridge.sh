#!/usr/bin/env bash
# start-gpg-bridge.sh
#
# Bridges the local GPG agent (exposed via socat TCP on Tailscale) to a Unix
# socket inside this devcontainer/Codespace.
#
# Required env vars:
#   GPG_FORWARDER_HOST  — Tailscale machine name or IP of the local machine
#                         running gpg-agent-forwarder (e.g. "red-fenrir" or "100.75.158.34")
#   GPG_FORWARDER_PORT  — TCP port (default: 23456)
#
# For GitHub Codespace: set GPG_FORWARDER_HOST and TAILSCALE_AUTH_KEY as Codespace secrets.
# For local devcontainer testing: set GPG_FORWARDER_HOST to the Docker host gateway IP.

set -euo pipefail

LOCAL_MACHINE="${GPG_FORWARDER_HOST:-}"
LOCAL_PORT="${GPG_FORWARDER_PORT:-23456}"
TS_SOCKET="/var/run/tailscale/tailscaled.sock"

# Resolve Tailscale hostname to IP (needed for userspace networking where MagicDNS is unavailable)
resolve_ts_host() {
  local host="$1"
  # Already an IP address — nothing to resolve
  if [[ "$host" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "$host"
    return
  fi
  # Try resolving via tailscale status --json
  if command -v tailscale &>/dev/null && [ -S "$TS_SOCKET" ]; then
    local ip
    ip=$(sudo tailscale --socket="$TS_SOCKET" status --json 2>/dev/null \
      | jq -r --arg name "$host" '.Peer[] | select(.HostName == $name) | .TailscaleIPs[0] // empty' 2>/dev/null \
      | head -1)
    if [ -n "$ip" ]; then
      echo "$ip"
      return
    fi
  fi
  # Fallback to the original hostname
  echo "$host"
}

GPG_SOCKET_DIR="$HOME/.gnupg"
GPG_SOCKET="$GPG_SOCKET_DIR/S.gpg-agent"
BRIDGE_PID_FILE="/tmp/gpg-bridge.pid"
BRIDGE_LOG="/tmp/gpg-bridge.log"

log() { echo "[gpg-bridge] $*"; }

if [ -z "$LOCAL_MACHINE" ]; then
  log "GPG_FORWARDER_HOST not set — skipping GPG bridge."
  log "Set it to your local machine's Tailscale name or Docker host IP."
  exit 0
fi

# Resolve Tailscale hostname to IP
RESOLVED=$(resolve_ts_host "$LOCAL_MACHINE")
if [ "$RESOLVED" != "$LOCAL_MACHINE" ]; then
  log "Resolved $LOCAL_MACHINE -> $RESOLVED"
fi
LOCAL_MACHINE="$RESOLVED"

# Kill any previous bridge instance
if [ -f "$BRIDGE_PID_FILE" ]; then
  OLD_PID=$(cat "$BRIDGE_PID_FILE")
  if kill -0 "$OLD_PID" 2>/dev/null; then
    log "Stopping previous bridge (PID $OLD_PID)..."
    kill "$OLD_PID" 2>/dev/null || true
  fi
  rm -f "$BRIDGE_PID_FILE"
fi

# Kill any running gpg-agent to prevent it from taking over the socket
log "Stopping any running gpg-agent..."
gpgconf --kill gpg-agent 2>/dev/null || true
pkill -u "$(id -u)" gpg-agent 2>/dev/null || true

rm -f "$GPG_SOCKET" "${GPG_SOCKET}.extra" "${GPG_SOCKET}.browser" "${GPG_SOCKET}.ssh"

# Prepare gnupg dir
mkdir -p "$GPG_SOCKET_DIR"
chmod 700 "$GPG_SOCKET_DIR"

# Check socat is available
if ! command -v socat &>/dev/null; then
  log "socat not found. Install it or add it to vscode.nix packages."
  exit 1
fi

# Verify the remote forwarder is reachable
log "Testing connection to $LOCAL_MACHINE:$LOCAL_PORT ..."
if ! socat /dev/null "TCP:$LOCAL_MACHINE:$LOCAL_PORT,connect-timeout=5" 2>/dev/null; then
  log "Cannot reach $LOCAL_MACHINE:$LOCAL_PORT."
  log "Ensure gpg-agent-forwarder is running on the local machine."
  log "Check: systemctl --user status gpg-agent-forwarder.service"
  exit 1
fi
log "Connection OK."

# Start the socat bridge in the background
log "Starting bridge: TCP $LOCAL_MACHINE:$LOCAL_PORT -> $GPG_SOCKET"
socat \
  "UNIX-LISTEN:$GPG_SOCKET,fork,unlink-early,mode=600" \
  "TCP:$LOCAL_MACHINE:$LOCAL_PORT" \
  >> "$BRIDGE_LOG" 2>&1 &

BRIDGE_PID=$!
echo "$BRIDGE_PID" > "$BRIDGE_PID_FILE"
log "Bridge started (PID $BRIDGE_PID). Log: $BRIDGE_LOG"

# Quick smoke-test: gpg-connect-agent should respond through the bridge
sleep 0.5

# Kill any gpg-agent that auto-started during setup (e.g. triggered by VS Code)
if pgrep -u "$(id -u)" gpg-agent >/dev/null 2>&1; then
  log "Detected auto-started gpg-agent, killing it..."
  pkill -u "$(id -u)" gpg-agent 2>/dev/null || true
  sleep 0.3
  # Socat's unlink-early means we need to re-check the socket
  if [ ! -S "$GPG_SOCKET" ]; then
    log "Socket was replaced by gpg-agent, restarting socat..."
    kill "$BRIDGE_PID" 2>/dev/null || true
    rm -f "$GPG_SOCKET"
    socat \
      "UNIX-LISTEN:$GPG_SOCKET,fork,unlink-early,mode=600" \
      "TCP:$LOCAL_MACHINE:$LOCAL_PORT" \
      >> "$BRIDGE_LOG" 2>&1 &
    BRIDGE_PID=$!
    echo "$BRIDGE_PID" > "$BRIDGE_PID_FILE"
    sleep 0.5
  fi
fi

if gpg-connect-agent --no-autostart -S "$GPG_SOCKET" /bye >/dev/null 2>&1; then
  log "GPG agent responds through bridge. Setup complete."
else
  log "Warning: GPG agent did not respond through bridge."
  log "Check log: $BRIDGE_LOG"
fi
