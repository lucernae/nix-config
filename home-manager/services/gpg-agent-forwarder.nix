# /workspaces/nix-config/home-manager/services/gpg-agent-forwarder.nix
{ config, pkgs, lib, ... }:

let
  # Script to safely start the socat forwarder.
  # It dynamically finds the Tailscale IP and GPG socket.
  gpg-forwarder-script = pkgs.writeShellScriptBin "gpg-agent-forwarder" ''
    #!/bin/sh
    set -e

    # Find Tailscale IP, exit if not available
    TS_IP=$(${pkgs.tailscale}/bin/tailscale ip -4)
    if [ -z "$TS_IP" ]; then
      echo "Tailscale IP not found. Is Tailscale running?"
      exit 1
    fi

    # Find GPG Agent socket, exit if not available
    GPG_SOCKET=$(${pkgs.gnupg}/bin/gpgconf --list-dirs agent-socket)
    if [ -z "$GPG_SOCKET" ]; then
      echo "GPG agent socket not found. Is gpg-agent running?"
      exit 1
    fi

    echo "Starting GPG agent forwarder on $TS_IP:23456"
    exec ${pkgs.socat}/bin/socat TCP-LISTEN:23456,bind=$TS_IP,fork UNIX-CONNECT:$GPG_SOCKET
  '';
in
{
  # This service is for macOS (darwin)
  launchd.agents.gpg-agent-forwarder = lib.mkIf pkgs.stdenv.isDarwin {
    enable = true;
    config = {
      Label = "com.user.gpg-agent-forwarder";
      Program = "${gpg-forwarder-script}/bin/gpg-agent-forwarder";
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/tmp/gpg-agent-forwarder.log";
      StandardErrorPath = "/tmp/gpg-agent-forwarder.log";
    };
  };
}
