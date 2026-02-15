# NixOS VM Configuration

This is a lightweight NixOS VM configuration suitable for testing and development.

## Features

- **Desktop Environment**: Xfce (lightweight)
- **Display Manager**: LightDM
- **Default User**: `vmuser` (password: `vmuser` - change after first login!)
- **Auto-login**: Enabled for convenience
- **SSH**: Enabled with password authentication
- **QEMU Guest Tools**: Enabled for better VM integration
- **SPICE Support**: For enhanced display and clipboard sharing

## Building the VM

To build a QEMU VM from this configuration:

```bash
nixos-rebuild build-vm --flake .#vm
```

This will create a `result` symlink containing the VM image and startup script.

## Running the VM

After building, run:

```bash
./result/bin/run-nixos-vm
```

The VM will start with:
- 2GB RAM (configurable via QEMU_OPTS environment variable)
- Network access via user-mode networking
- SSH accessible on localhost:2222 (if port forwarding is configured)

## Customizing VM Resources

You can customize the VM by setting environment variables:

```bash
# Run with 4GB RAM
QEMU_OPTS="-m 4096" ./result/bin/run-nixos-vm

# Run with 4GB RAM and 4 CPUs
QEMU_OPTS="-m 4096 -smp 4" ./result/bin/run-nixos-vm
```

## SSH Access

To enable SSH access to the VM, you can use port forwarding:

```bash
QEMU_NET_OPTS="hostfwd=tcp::2222-:22" ./result/bin/run-nixos-vm
```

Then connect with:

```bash
ssh -p 2222 vmuser@localhost
```

## Post-Installation

1. **Change the default password**:
   ```bash
   passwd
   ```

2. **Update the system**:
   ```bash
   sudo nixos-rebuild switch
   ```

## Integration with Flake

Make sure to add this configuration to your flake.nix:

```nix
nixosConfigurations.vm = nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  modules = [
    ./systems/nixos/vm
  ];
};
```
