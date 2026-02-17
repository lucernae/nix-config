# GPG Unix Socket Forwarding — Method B: Tailscale + socat

Forward local GPG agent to GitHub Codespace / VSCode Dev Containers so signing
works with local keys and pinentry appears on the local machine.

## Architecture

```
[Local Machine (lucernae / recalune)]          [Devcontainer / Codespace]
─────────────────────────────────────          ────────────────────────────
gpg-agent                                      gpg CLI (git commit -S)
    │ S.gpg-agent (Unix socket)                     │
    ▼                                               ▼
socat server (gpg-agent-forwarder)             socat client (start-gpg-bridge.sh)
  binds TCP :23456 on Tailscale IP               connects TCP → creates Unix socket
    │                                               │ ~/.gnupg/S.gpg-agent
    └──────────── Tailscale mesh VPN ───────────────┘
```

## Existing State

| File | Status | Notes |
|------|--------|-------|
| [home-manager/services/gpg-agent-forwarder.nix](home-manager/services/gpg-agent-forwarder.nix) | Exists | Server-side socat script. macOS launchd only, `enable = false` |
| [home-manager/services/gpg-agent.nix](home-manager/services/gpg-agent.nix) | Exists | Has `allow-loopback-pinentry`, `enable-ssh-support` |
| [home-manager/recalune.nix](home-manager/recalune.nix) | Exists | Already imports `gpg-agent-forwarder.nix`, has `socat` pkg |
| [home-manager/lucernae.nix](home-manager/lucernae.nix) | Exists | Does NOT import `gpg-agent-forwarder.nix` |
| [home-manager/vscode.nix](home-manager/vscode.nix) | Exists | Already has `socat`, `tailscale`, `procps` pkgs |
| [home-manager/programs/git-vscode.nix](home-manager/programs/git-vscode.nix) | Exists | GPG signing enabled, key `69AC1656`, `signByDefault = true` |
| `.devcontainer/scripts/start-gpg-bridge.sh` | Does NOT exist | Needs to be created |

---

## Phase 1: Validate local GPG + socat bridge (no Docker, no Tailscale)

**Goal:** Prove the socat TCP-bridge-over-Unix-socket mechanism works locally.

### Setup

```bash
# 1. Confirm gpg-agent is running and find socket path
gpgconf --list-dirs agent-socket
# Expected: /run/user/1000/gnupg/S.gpg-agent

# 2. Start socat server on localhost (not Tailscale — just local loopback)
socat TCP-LISTEN:23456,bind=127.0.0.1,fork UNIX-CONNECT:$(gpgconf --list-dirs agent-socket) &
SOCAT_SERVER_PID=$!

# 3. Start socat client — creates a test socket that bridges back to the server
mkdir -p /tmp/gpg-bridge-test
socat UNIX-LISTEN:/tmp/gpg-bridge-test/S.gpg-agent,fork,unlink-early TCP:127.0.0.1:23456 &
SOCAT_CLIENT_PID=$!
```

### Test

```bash
# 4. Tell GPG to use the bridged socket
echo "test" | gpg --homedir /tmp/gpg-bridge-test --no-autostart \
  --keyring ~/.gnupg/pubring.kbx --secret-keyring ~/.gnupg/trustdb.gpg \
  -as --local-user 69AC1656 -
```

Alternative simpler test — just check the agent responds through the bridge:

```bash
gpg-connect-agent --no-autostart -S /tmp/gpg-bridge-test/S.gpg-agent /bye
# Expected: "OK closing connection"
```

### Cleanup

```bash
kill $SOCAT_CLIENT_PID $SOCAT_SERVER_PID 2>/dev/null
rm -rf /tmp/gpg-bridge-test
```

### What this validates
- socat can bridge a GPG Unix socket over TCP and back
- The bridged socket is functional for GPG agent protocol

---

## Phase 2: Enable local forwarder service (systemd for Linux)

**Goal:** `gpg-agent-forwarder.nix` runs as a systemd user service on Linux, binding to Tailscale IP.

### Changes to `home-manager/services/gpg-agent-forwarder.nix`

Add a `systemd.user.services` block for Linux (currently only has `launchd.agents` for macOS).
Enable the macOS launchd service (currently `enable = false`).

```nix
{ config, pkgs, lib, ... }:

let
  gpg-forwarder-script = pkgs.writeShellScriptBin "gpg-agent-forwarder" ''
    set -e

    TAILSCALE_BIN=${if pkgs.stdenv.isDarwin
      then "/Applications/Tailscale.app/Contents/MacOS/Tailscale"
      else "${pkgs.tailscale}/bin/tailscale"}

    TS_IP=$($TAILSCALE_BIN ip -4 2>/dev/null)
    if [ -z "$TS_IP" ]; then
      echo "Tailscale IP not found. Is Tailscale running?" >&2
      exit 1
    fi

    GPG_SOCKET=$(${pkgs.gnupg}/bin/gpgconf --list-dirs agent-socket)
    if [ -z "$GPG_SOCKET" ]; then
      echo "GPG agent socket not found. Is gpg-agent running?" >&2
      exit 1
    fi

    echo "Starting GPG agent forwarder on $TS_IP:23456 -> $GPG_SOCKET"
    exec ${pkgs.socat}/bin/socat TCP-LISTEN:23456,bind=$TS_IP,reuseaddr,fork UNIX-CONNECT:$GPG_SOCKET
  '';
in
{
  # macOS (launchd)
  launchd.agents.gpg-agent-forwarder = lib.mkIf pkgs.stdenv.isDarwin {
    enable = true;
    config = {
      Label = "id.maulana.gpg-agent-forwarder";
      Program = "${gpg-forwarder-script}/bin/gpg-agent-forwarder";
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/tmp/gpg-agent-forwarder.log";
      StandardErrorPath = "/tmp/gpg-agent-forwarder.log";
    };
  };

  # Linux (systemd user service)
  systemd.user.services.gpg-agent-forwarder = lib.mkIf pkgs.stdenv.isLinux {
    Unit = {
      Description = "GPG Agent TCP Forwarder over Tailscale";
      After = [ "gpg-agent.socket" ];
    };
    Service = {
      ExecStart = "${gpg-forwarder-script}/bin/gpg-agent-forwarder";
      Restart = "on-failure";
      RestartSec = "5s";
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
```

### Changes to `home-manager/lucernae.nix`

Add import of `./services/gpg-agent-forwarder.nix`.

### Apply & Test

```bash
# Apply home-manager config
hmsf

# Enable and start the service
systemctl --user daemon-reload
systemctl --user enable gpg-agent-forwarder.service
systemctl --user start gpg-agent-forwarder.service

# Verify it's running
systemctl --user status gpg-agent-forwarder.service
# Expected: active (running)

# Verify it's listening on the Tailscale IP
ss -tlnp | grep 23456
# Expected: LISTEN  ... <tailscale-ip>:23456

# Verify the forwarder responds to GPG protocol
TS_IP=$(tailscale ip -4)
gpg-connect-agent --no-autostart -S "tcp://$TS_IP:23456" /bye 2>/dev/null \
  || socat - TCP:$TS_IP:23456 <<< ""
# Confirm the TCP port accepts connections
```

### What this validates
- systemd user service starts correctly after hmsf
- socat binds to the Tailscale interface
- The forwarder is reachable over TCP

---

## Phase 3: Build and start the devcontainer on nix-linux-builder

**Goal:** The `home-manager` devcontainer builds successfully and the GPG bridge
prerequisites (socat, gpg) are available inside.

### Why nix-linux-builder

Building locally is slow (large Nix image). `nix-linux-builder` (116.203.210.37) has:
- Docker 28.5.2 running (`virtualisation.docker.enable = true`)
- Tailscale IP `100.127.169.24` — on the same mesh as `red-fenrir` (`100.75.158.34`)
- This means a container on the remote can reach the local GPG forwarder via Tailscale

### Setup: Docker context for nix-linux-builder

```bash
# Create a persistent Docker context (one-time)
docker context create nix-linux-builder \
  --docker "host=ssh://root@116.203.210.37" \
  --description "nix-linux-builder remote Docker"
```

### Build (image built on remote, context sent from local)

`devcontainer build` sends the local build context (Dockerfile + library-scripts) to the
remote Docker daemon. The `COPY library-scripts` step uses local files. The resulting
image is stored on the remote.

```bash
DOCKER_CONTEXT=nix-linux-builder devcontainer build \
  --workspace-folder ~/.config/nix-config \
  --config ~/.config/nix-config/.devcontainer/home-manager/devcontainer.json
```

### Start (up) on nix-linux-builder

`devcontainer up` uses docker-compose. The volume mount `../../../:/workspaces:cached`
references a path on the remote. So the repo must exist on the remote at a path such
that `<repo>/.devcontainer/home-manager/../../../` resolves to `/root/` (i.e. repo at
`/root/nix-config`).

```bash
# 1. Clone (or sync) the repo to the remote
ssh root@116.203.210.37 '
  [ -d /root/nix-config ] || git clone https://github.com/lucernae/nix-config /root/nix-config
  cd /root/nix-config && git pull
'

# 2. Install devcontainer CLI on remote (one-time, via npm)
ssh root@116.203.210.37 'which devcontainer || npm install -g @devcontainers/cli'

# 3. Start the devcontainer on the remote
ssh root@116.203.210.37 '
  devcontainer up \
    --workspace-folder /root/nix-config \
    --config /root/nix-config/.devcontainer/home-manager/devcontainer.json
'
```

### Test: container starts and has prerequisites

```bash
ssh root@116.203.210.37 '
  devcontainer exec \
    --workspace-folder /root/nix-config \
    --config /root/nix-config/.devcontainer/home-manager/devcontainer.json \
    bash -l -c "
      echo === socat ===
      which socat && socat -V | head -1

      echo === gpg ===
      which gpg && gpg --version | head -1

      echo === gnupg dir ===
      ls -la ~/.gnupg/ 2>/dev/null || echo ~/.gnupg does not exist yet

      echo === bridge script ===
      ls -la /workspaces/nix-config/.devcontainer/scripts/start-gpg-bridge.sh
    "
'
```

### What this validates
- Docker image builds without errors on the remote
- Container starts and stays running (postCreateCommand ran)
- `socat`, `gpg` are available inside (from `vscode.nix` packages)
- Workspace mount is correct: `/workspaces/nix-config` maps to `/root/nix-config`
- Bridge script is visible at the expected path

---

## Phase 4: Create the bridge script and test inside devcontainer

**Goal:** Create `.devcontainer/scripts/start-gpg-bridge.sh` and verify it bridges
the GPG socket from the host into the container.

### Create `.devcontainer/scripts/start-gpg-bridge.sh`

```bash
#!/usr/bin/env bash
# Bridges local GPG agent (via Tailscale TCP) to a Unix socket inside the container.
# Called as postStartCommand in devcontainer.json.
set -euo pipefail

LOCAL_MACHINE="${GPG_FORWARDER_HOST:-}"
LOCAL_PORT="${GPG_FORWARDER_PORT:-23456}"

if [ -z "$LOCAL_MACHINE" ]; then
  echo "[gpg-bridge] GPG_FORWARDER_HOST not set. Skipping GPG bridge setup."
  echo "[gpg-bridge] Set it as a Codespace secret or in remoteEnv to enable."
  exit 0
fi

GPG_SOCKET_DIR="$HOME/.gnupg"
GPG_SOCKET="$GPG_SOCKET_DIR/S.gpg-agent"

mkdir -p "$GPG_SOCKET_DIR"
chmod 700 "$GPG_SOCKET_DIR"

# Kill any previous bridge
if [ -f /tmp/gpg-bridge.pid ]; then
  kill "$(cat /tmp/gpg-bridge.pid)" 2>/dev/null || true
  rm -f /tmp/gpg-bridge.pid
fi
rm -f "$GPG_SOCKET"

# Verify connectivity first
if ! socat /dev/null "TCP:$LOCAL_MACHINE:$LOCAL_PORT" 2>/dev/null; then
  echo "[gpg-bridge] Cannot reach $LOCAL_MACHINE:$LOCAL_PORT. Is the forwarder running?"
  echo "[gpg-bridge] Skipping GPG bridge setup."
  exit 0
fi

echo "[gpg-bridge] Starting: $LOCAL_MACHINE:$LOCAL_PORT -> $GPG_SOCKET"
socat UNIX-LISTEN:"$GPG_SOCKET",fork,unlink-early \
  "TCP:$LOCAL_MACHINE:$LOCAL_PORT" \
  >> /tmp/gpg-bridge.log 2>&1 &

echo $! > /tmp/gpg-bridge.pid
echo "[gpg-bridge] Started (PID $(cat /tmp/gpg-bridge.pid)). Log: /tmp/gpg-bridge.log"
```

### Update `devcontainer.json` to run the bridge on start

In `.devcontainer/home-manager/devcontainer.json`, add `postStartCommand`:

```json
"postStartCommand": "bash /workspaces/nix-config/.devcontainer/scripts/start-gpg-bridge.sh || true"
```

Also add `remoteEnv` for the forwarder host:

```json
"remoteEnv": {
  "LOCAL_WORKSPACE_FOLDER": "${localWorkspaceFolder}",
  "GPG_FORWARDER_HOST": "${localEnv:GPG_FORWARDER_HOST}",
  "GPG_FORWARDER_PORT": "${localEnv:GPG_FORWARDER_PORT}"
}
```

### Test: Real Tailscale path via nix-linux-builder

Since the container runs on `nix-linux-builder` (Tailscale `100.127.169.24`) and the
GPG forwarder is on `red-fenrir` (Tailscale `100.75.158.34`), the test is real
end-to-end — no fake Docker-bridge workaround needed.

```bash
DC_REMOTE_FLAGS="--workspace-folder /root/nix-config --config /root/nix-config/.devcontainer/home-manager/devcontainer.json"

# 1. Inside the container: run the bridge script pointing at red-fenrir's Tailscale IP
ssh root@116.203.210.37 "
  devcontainer exec $DC_REMOTE_FLAGS \
    bash -c 'GPG_FORWARDER_HOST=100.75.158.34 bash /workspaces/nix-config/.devcontainer/scripts/start-gpg-bridge.sh'
"

# 2. Test GPG agent responds through the bridge
ssh root@116.203.210.37 "
  devcontainer exec $DC_REMOTE_FLAGS \
    bash -c 'gpg-connect-agent --no-autostart -S ~/.gnupg/S.gpg-agent /bye'
"
# Expected: "OK closing connection"

# 3. Test GPG signing (requires public key to be imported in the container's keyring)
ssh root@116.203.210.37 "
  devcontainer exec $DC_REMOTE_FLAGS \
    bash -c 'echo test | gpg --no-autostart -as --local-user 69AC1656 -' 2>&1
"
```

### What this validates
- The bridge script runs without errors
- socat creates the Unix socket inside the container
- The GPG agent protocol works through real Tailscale + socat bridge
- The script gracefully skips when `GPG_FORWARDER_HOST` is unset

---

## Phase 5: Tailscale inside the devcontainer (for Codespace)

**Goal:** Tailscale runs inside the container and can reach the local machine's forwarder.

### Tailscale in the devcontainer

The `home-manager` devcontainer already has `privileged: true` in `docker-compose.yml`, which is required for Tailscale's TUN device.

Two options:

#### Option A: Tailscale devcontainer feature (for `devcontainer-features` config)

Add to `.devcontainer/devcontainer-features/devcontainer.json`:
```json
"features": {
  "ghcr.io/tailscale/devcontainer-feature/tailscale:1": {}
}
```

#### Option B: Tailscale via home-manager (for `home-manager` config)

Already in `vscode.nix`: `pkgs.tailscale` is included. The Tailscale daemon (`tailscaled`) needs to be started manually or via a postCreate hook since the container doesn't run systemd.

Add to `.devcontainer/scripts/start-gpg-bridge.sh` (before the connectivity check):

```bash
# Start Tailscale daemon if not running
if ! pgrep -x tailscaled >/dev/null 2>&1; then
  echo "[gpg-bridge] Starting tailscaled..."
  sudo tailscaled --state=/var/lib/tailscale/tailscaled.state --socket=/var/run/tailscale/tailscaled.sock &
  sleep 2
fi

# Authenticate Tailscale (requires TAILSCALE_AUTH_KEY secret for unattended)
if ! tailscale status >/dev/null 2>&1; then
  if [ -n "${TAILSCALE_AUTH_KEY:-}" ]; then
    echo "[gpg-bridge] Authenticating Tailscale with auth key..."
    sudo tailscale up --authkey="$TAILSCALE_AUTH_KEY" --hostname="codespace-$(hostname | cut -c1-20)"
  else
    echo "[gpg-bridge] Tailscale not authenticated. Run 'sudo tailscale up' manually."
    echo "[gpg-bridge] Or set TAILSCALE_AUTH_KEY as a Codespace secret for auto-auth."
    exit 0
  fi
fi
```

### GitHub Codespace Secrets (user-configured, not automatable)

| Secret Name | Value | Purpose |
|-------------|-------|---------|
| `GPG_FORWARDER_HOST` | Tailscale machine name of local laptop (e.g., `red-fenrir`) | Where to connect for GPG |
| `TAILSCALE_AUTH_KEY` | Pre-auth key from Tailscale admin console | Unattended Tailscale login |

### Test: Tailscale connectivity inside container

```bash
# Inside the running devcontainer:
docker compose exec -u vscode devcontainer bash -c '
  # Check Tailscale status
  tailscale status

  # Ping the local machine
  tailscale ping $GPG_FORWARDER_HOST

  # Full bridge test
  bash /workspaces/nix-config/.devcontainer/scripts/start-gpg-bridge.sh
  gpg-connect-agent --no-autostart -S ~/.gnupg/S.gpg-agent /bye
'
```

### What this validates
- Tailscale can run inside the privileged container
- Tailscale mesh reaches the local machine
- The full Tailscale + socat chain works end-to-end

---

## Summary of Changes

### Files to modify

| File | Change |
|------|--------|
| `home-manager/services/gpg-agent-forwarder.nix` | Add `systemd.user.services` for Linux; enable macOS launchd; add `reuseaddr` to socat |
| `home-manager/lucernae.nix` | Add import `./services/gpg-agent-forwarder.nix` |

### Files to create

| File | Purpose |
|------|---------|
| `.devcontainer/scripts/start-gpg-bridge.sh` | Client-side socat bridge for inside containers |

### Files to update

| File | Change |
|------|--------|
| `.devcontainer/home-manager/devcontainer.json` | Add `postStartCommand` and `remoteEnv` for GPG bridge |

### No changes needed

| File | Reason |
|------|--------|
| `home-manager/vscode.nix` | Already has `socat`, `tailscale`, `procps` |
| `home-manager/recalune.nix` | Already imports `gpg-agent-forwarder.nix` and has `socat` |
| `home-manager/services/gpg-agent.nix` | Already has `allow-loopback-pinentry` |

---

## Execution Order

```
Phase 1 (local socat test)      ← No config changes, just validates mechanism
    │
Phase 2 (systemd forwarder)     ← Modifies gpg-agent-forwarder.nix + lucernae.nix
    │                              Runs: hmsf
    │
Phase 3 (devcontainer build)    ← Creates start-gpg-bridge.sh
    │                              Updates devcontainer.json
    │                              Runs: docker compose build && up
    │
Phase 4 (bridge test)           ← Tests bridge via Docker networking (no Tailscale)
    │
Phase 5 (Tailscale in container) ← Tests full Tailscale path (requires auth)
```

Phases 1-4 can be executed and tested by Claude without user interaction.
Phase 5 requires user to provide Tailscale auth key or manually run `sudo tailscale up`.
