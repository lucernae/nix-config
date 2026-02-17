{ config, pkgs, lib, ... }:

let
  cfg = config.myConfig.gpgForwarding;

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
  launchd.agents.gpg-agent-forwarder = lib.mkIf (cfg.enable && pkgs.stdenv.isDarwin) {
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
  systemd.user.services.gpg-agent-forwarder = lib.mkIf (cfg.enable && pkgs.stdenv.isLinux) {
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
