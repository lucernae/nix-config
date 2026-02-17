{ config, pkgs, lib, ... }:
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
  ];

  # Prevent gpg from auto-starting a local gpg-agent;
  # the devcontainer uses a socat bridge to the remote agent instead.
  programs.gpg.settings.no-autostart = true;

  home.packages = [
    pkgs.claude-code    # Claude Code CLI
    pkgs.docker-client  # Docker CLI (uses host socket)
    pkgs.tailscale      # Tailscale mesh VPN
    pkgs.socat          # Required for GPG forwarding bridge
    pkgs.procps         # Provides pgrep/pkill
    pkgs.jq             # JSON processing
  ] ++ lib.optionals (builtins.getEnv "CODESPACES" == "true") [
    pkgs.xdg-utils
  ];

}
