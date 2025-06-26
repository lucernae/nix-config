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
    ./programs/zsh.nix
    ./programs/starship.nix
    ./programs/gemini-cli.nix
  ];

  # Conditionally install xdg-utils in GitHub Codespaces
  home.packages = lib.mkIf (builtins.getEnv "CODESPACES" == "true") [
    pkgs.xdg-utils
    pkgs.socat # New: Required for GPG forwarding
    pkgs.tailscale # New: Required for GPG forwarding
  ];

}
