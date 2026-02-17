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

  home.packages = [
    pkgs.socat    # Required for GPG forwarding bridge
    pkgs.procps   # Provides pgrep/pkill
  ] ++ lib.optionals (builtins.getEnv "CODESPACES" == "true") [
    pkgs.xdg-utils
  ];

}
