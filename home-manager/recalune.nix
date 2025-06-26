{ config, pkgs, ... }:
{
  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "recalune";
  home.homeDirectory = "/Users/recalune";

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
    ./services/gpg-agent-forwarder.nix # New: GPG agent forwarder service
  ];

  home.packages = with pkgs; [
    obsidian
    raycast
    socat # New: Required for GPG forwarding
    tailscale # New: Required for GPG forwarding
  ];

}
