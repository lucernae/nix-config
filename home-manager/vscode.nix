{ config, pkgs, lib, ... }:

let
  cfg = config.myConfig.gpgForwarding;
in
{
  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "vscode";
  home.homeDirectory = "/home/vscode";

  imports = [
    ./home.nix
    ./programs/direnv.nix
    ./programs/git-vscode.nix
    ./programs/gpg.nix
    ./programs/zsh.nix
    ./programs/starship.nix
    ./programs/gemini-cli.nix
    ./programs/claude-code.nix
  ];

  # Prevent gpg from auto-starting a local gpg-agent when receiving forwarded agent;
  # the devcontainer uses a socat bridge to the remote agent instead.
  programs.gpg.settings.no-autostart = lib.mkDefault cfg.enable;

  # Packages always needed in the devcontainer (independent of feature flag)
  # These are used by start-gpg-bridge.sh which runs conditionally at runtime
  home.packages = [
    pkgs.unstable.opencode
    pkgs.docker-client # Docker CLI (uses host socket)
    pkgs.tailscale # Tailscale mesh VPN (for GPG bridge)
    pkgs.socat # Required for GPG forwarding bridge
    pkgs.procps # Provides pgrep/pkill
    pkgs.jq # JSON processing
    pkgs.iproute2 # Provides ip link (used to detect kernel TUN vs userspace networking)
  ] ++ lib.optionals (builtins.getEnv "CODESPACES" == "true") [
    pkgs.xdg-utils
  ];

}
