{ config, pkgs, lib, ... }:

let
  cfg = config.myConfig.gpgForwarding;
in
{
  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "recalune";
  home.homeDirectory = "/Users/recalune";

  # Enable GPG agent forwarding over Tailscale
  myConfig.gpgForwarding.enable = true;

  imports = [
    ./home.nix
    ./programs/direnv.nix
    ./programs/git.nix
    ./programs/gpg.nix
    ./programs/zsh.nix
    ./programs/vscode.nix
    ./programs/vim.nix
    ./programs/starship.nix
    ./services/gpg-agent.nix
    ./programs/gemini-cli.nix
  ] ++ lib.optional cfg.enable ./services/gpg-agent-forwarder.nix;

  home.packages = with pkgs; [
    obsidian
    raycast
    socat # Required for GPG forwarding
    colima
    pinentry-box-cli
    # tailscale # Tailscale package provided by nix homebrew
  ];

}
