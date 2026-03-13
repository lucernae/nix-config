{ config, pkgs, ... }:

let
  vpnToggleScript = pkgs.writeShellScriptBin "vpn-toggle" ''
    CONNECTION_NAME="pvdata"

    # Check if connection is active
    if ${pkgs.networkmanager}/bin/nmcli connection show --active | grep -q "$CONNECTION_NAME"; then
      echo "Disconnecting VPN..."
      ${pkgs.networkmanager}/bin/nmcli connection down "$CONNECTION_NAME"
      echo "✓ VPN disconnected"
    else
      echo "Connecting VPN..."
      ${pkgs.networkmanager}/bin/nmcli connection up "$CONNECTION_NAME"
      echo "✓ VPN connected"
    fi
  '';
in
{
  # Add VPN toggle command to system packages
  environment.systemPackages = [ vpnToggleScript ];

  # Add convenient aliases for VPN control
  environment.shellAliases = {
    vpn = "vpn-toggle";
    vpn-status = "${pkgs.networkmanager}/bin/nmcli connection show --active | grep pvdata || echo 'VPN is disconnected'";
  };

  # Systemd service to auto-import WireGuard configuration if it exists
  # This allows keeping WireGuard settings out of git while maintaining
  # a hermetic, reproducible setup
  #
  # Usage:
  #   1. Place your WireGuard config at: ~/.config/nix-config/systems/nixos/red-fenrir/pvdata.conf
  #   2. Rebuild NixOS: nrsf
  #   3. The service will auto-import the config on next boot (or run manually)
  #
  # To manually trigger: sudo systemctl start wireguard-auto-import

  systemd.services.wireguard-auto-import = {
    description = "Auto-import WireGuard VPN configuration if present";
    wantedBy = [ "multi-user.target" ];
    after = [ "NetworkManager.service" ];
    wants = [ "NetworkManager.service" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    script = ''
      CONFIG_FILE="${config.users.users.lucernae.home}/.config/nix-config/systems/nixos/red-fenrir/pvdata.conf"
      CONNECTION_NAME="pvdata"

      # Check if config file exists
      if [ ! -f "$CONFIG_FILE" ]; then
        echo "WireGuard config not found at $CONFIG_FILE - skipping auto-import"
        echo "To set up WireGuard, place a wireguard.conf file at: $CONFIG_FILE"
        exit 0
      fi

      # Check if connection already exists
      if ${pkgs.networkmanager}/bin/nmcli connection show "$CONNECTION_NAME" &>/dev/null; then
        echo "WireGuard connection '$CONNECTION_NAME' already exists - skipping import"
        exit 0
      fi

      # Import the configuration
      echo "Importing WireGuard configuration from $CONFIG_FILE"
      ${pkgs.networkmanager}/bin/nmcli connection import type wireguard file "$CONFIG_FILE"

      if [ $? -eq 0 ]; then
        echo "Successfully imported WireGuard connection '$CONNECTION_NAME'"
        # Disable auto-connect by default (manual toggle from KDE)
        ${pkgs.networkmanager}/bin/nmcli connection modify "$CONNECTION_NAME" connection.autoconnect no
        echo "VPN can now be toggled from KDE network applet"
      else
        echo "Failed to import WireGuard configuration"
        exit 1
      fi
    '';
  };
}
