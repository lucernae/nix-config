{ config, pkgs, ... }:
{
  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "lucernae";
  home.homeDirectory = "/home/lucernae";

  imports = [
    ./home.nix
    ./programs/direnv.nix
    ./programs/git.nix
    ./programs/gpg.nix
    ./programs/zsh.nix
    ./programs/vscode.nix
    ./programs/vim.nix
    ./programs/starship.nix
    ./programs/claude-code.nix
    ./programs/vicinae.nix
    ./services/gpg-agent.nix
    ./services/gpg-agent-forwarder.nix
  ];

  home.packages = with pkgs; [
    kubernetes-helm
    kubectl
    ghostty
    jetbrains-toolbox
    bottles
    pcsx2
    devcontainer
    kdePackages.kgpg
    kwalletcli
  ];

  home.sessionPath = [
    "$HOME/.local/share/JetBrains/Toolbox/scripts"
  ];

}
