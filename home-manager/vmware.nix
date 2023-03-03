{ config, pkgs, ... }:
{
  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "vmware";
  home.homeDirectory = "/home/vmware";

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
  ];

}
