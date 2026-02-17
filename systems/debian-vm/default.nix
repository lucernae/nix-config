# Debian VM launcher package (headless/server, no GUI).
#
# Uses the official Debian genericcloud QCOW2 image — no installer needed.
# Cloud-init configures the user/password on the first boot.
#
# Usage:
#   nix run .#debian-vm               # start VM (downloads image on first run)
#   FRESH=1 nix run .#debian-vm       # wipe disk and start fresh (keeps base image)
#   VM_DIR=/path nix run .#debian-vm  # custom disk location
#   MEMORY=4G CPUS=4 nix run .#debian-vm
#   VM_USER=alice VM_PASS=secret nix run .#debian-vm
#   HOST_SHARE=/path nix run .#debian-vm  # mount host dir at /mnt/host inside VM
#
# Console: serial (no display window). Exit QEMU: Ctrl-A X
# SSH into running VM:
#   ssh -p 2222 <VM_USER>@localhost

{ pkgs, lib ? pkgs.lib }:

let
  debianRelease = "bookworm"; # Debian 12 stable
  debianVersion = "12";

  # genericcloud: minimal, optimized for VMs (smaller than generic)
  defaultImageUrl = "https://cloud.debian.org/images/cloud/${debianRelease}/latest/debian-${debianVersion}-genericcloud-amd64.qcow2";

in
pkgs.writeShellScriptBin "debian-vm" ''
  set -euo pipefail

  VM_DIR="''${VM_DIR:-$HOME/.local/share/debian-vm}"
  DISK_SIZE="''${DISK_SIZE:-20G}"
  MEMORY="''${MEMORY:-2G}"
  CPUS="''${CPUS:-2}"
  SSH_PORT="''${SSH_PORT:-2222}"
  IMAGE_URL="''${IMAGE_URL:-${defaultImageUrl}}"
  VM_USER="''${VM_USER:-debian}"
  VM_PASS="''${VM_PASS:-debian}"
  HOST_SHARE="''${HOST_SHARE:-}"

  FRESH="''${FRESH:-0}"

  mkdir -p "$VM_DIR"

  DISK="$VM_DIR/debian.qcow2"
  BASE_IMAGE="$VM_DIR/debian-base.qcow2"
  SEED_ISO="$VM_DIR/cloud-init-seed.iso"

  # ── Fresh start ───────────────────────────────────────────────────────────
  if [ "$FRESH" = "1" ]; then
    echo "==> FRESH=1: removing existing VM disk and seed (base image kept)..."
    rm -f "$DISK" "$SEED_ISO"
  fi

  # ── First-time setup ─────────────────────────────────────────────────────
  if [ ! -f "$DISK" ]; then
    echo "==> Debian VM disk not found. Running first-time setup..."

    # Download Debian cloud image
    if [ ! -f "$BASE_IMAGE" ] || [ "$(${pkgs.coreutils}/bin/stat -c%s "$BASE_IMAGE")" -lt 1000000 ]; then
      echo "==> Downloading Debian ${debianVersion} (${debianRelease}) cloud image..."
      echo "    URL: $IMAGE_URL"
      echo "    Override with: IMAGE_URL=<url> nix run .#debian-vm"
      ${pkgs.curl}/bin/curl -L --progress-bar -C - -o "$BASE_IMAGE" "$IMAGE_URL"
    else
      echo "==> Reusing cached base image at $BASE_IMAGE"
    fi

    # Create writable copy and resize
    echo "==> Creating VM disk ($DISK_SIZE) from base image..."
    ${pkgs.qemu}/bin/qemu-img convert -O qcow2 "$BASE_IMAGE" "$DISK"
    ${pkgs.qemu}/bin/qemu-img resize "$DISK" "$DISK_SIZE"

    # Generate cloud-init seed ISO (NoCloud data source)
    echo "==> Generating cloud-init seed (user: $VM_USER)..."
    SEED_DIR=$(${pkgs.coreutils}/bin/mktemp -d)
    trap '${pkgs.coreutils}/bin/rm -rf "$SEED_DIR"' EXIT

    VM_PASS_HASH=$(printf '%s' "$VM_PASS" | ${pkgs.openssl}/bin/openssl passwd -6 -stdin)

    cat > "$SEED_DIR/meta-data" << METADATA
instance-id: debian-vm-01
local-hostname: debian-vm
METADATA

    cat > "$SEED_DIR/user-data" << USERDATA
#cloud-config
users:
  - name: $VM_USER
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    lock_passwd: false
    passwd: $VM_PASS_HASH
    groups: [sudo]

chpasswd:
  expire: false

ssh_pwauth: true

# Grow root partition to fill the resized disk
growpart:
  mode: auto
  devices: [/]
resize_rootfs: true

packages:
  - vim
  - curl
  - git
  - htop
USERDATA

    # network-config: tell cloud-init to bring up the NIC via DHCP.
    # Without this, the Debian genericcloud image leaves the interface DOWN.
    cat > "$SEED_DIR/network-config" << NETCONFIG
version: 2
ethernets:
  ens3:
    dhcp4: true
    nameservers:
      addresses: [1.1.1.1, 8.8.8.8]
NETCONFIG

    ${pkgs.cdrkit}/bin/genisoimage \
      -output "$SEED_ISO" \
      -volid cidata \
      -joliet \
      -rock \
      "$SEED_DIR/user-data" \
      "$SEED_DIR/meta-data" \
      "$SEED_DIR/network-config" \
      2>/dev/null

    echo ""
    echo "==> First boot: cloud-init will configure user '$VM_USER'."
    echo "    Default password: $VM_PASS  (change it after login!)"
    echo "    SSH: ssh -p $SSH_PORT $VM_USER@localhost"
    echo "    Console exit: Ctrl-A X"
    echo ""
  fi

  # ── Start VM ─────────────────────────────────────────────────────────────

  # Detect KVM availability
  KVM_ARGS=()
  if [ -r /dev/kvm ]; then
    KVM_ARGS=(-enable-kvm -cpu host)
    echo "==> KVM acceleration: enabled"
  else
    echo "WARNING: /dev/kvm not available — falling back to software emulation (TCG)."
    echo "         Performance will be very slow."
    echo "         To fix: enable AMD SVM (AMD-V) in BIOS/UEFI settings, then reboot."
    KVM_ARGS=(-machine accel=tcg -cpu qemu64)
  fi

  MONITOR_SOCK="$VM_DIR/monitor.sock"
  rm -f "$MONITOR_SOCK"

  echo "==> Starting Debian VM (headless)..."
  echo "    SSH:     ssh -p $SSH_PORT $VM_USER@localhost"
  echo "    Monitor: ${pkgs.socat}/bin/socat - UNIX-CONNECT:$MONITOR_SOCK"
  echo "    Console: switch between serial/monitor with Ctrl-A C; exit with Ctrl-A X"
  echo ""

  SEED_ARGS=()
  if [ -f "$SEED_ISO" ]; then
    SEED_ARGS=(-drive "file=$SEED_ISO,format=raw,if=virtio,readonly=on")
  fi

  SHARE_ARGS=()
  if [ -n "$HOST_SHARE" ]; then
    echo "    Host share: $HOST_SHARE → /mnt/host (mount inside VM with: sudo mount -t 9p -o trans=virtio hostshare /mnt/host)"
    SHARE_ARGS=(-virtfs "local,path=$HOST_SHARE,mount_tag=hostshare,security_model=mapped-xattr")
  fi

  ${pkgs.qemu}/bin/qemu-system-x86_64 \
    "''${KVM_ARGS[@]}" \
    -m "$MEMORY" \
    -smp "$CPUS" \
    -drive "file=$DISK,format=qcow2,if=virtio" \
    "''${SEED_ARGS[@]}" \
    "''${SHARE_ARGS[@]}" \
    -nographic \
    -serial mon:stdio \
    -monitor "unix:$MONITOR_SOCK,server,nowait" \
    -netdev "user,id=net0,hostfwd=tcp::''${SSH_PORT}-:22" \
    -device virtio-net-pci,netdev=net0
''
