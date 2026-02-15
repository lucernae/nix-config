{ config, pkgs, ... }:
{
  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "vmuser";
  home.homeDirectory = "/home/vmuser";

  imports = [
    ./home.nix
    ./programs/direnv.nix
    ./programs/git.nix
    ./programs/vim.nix
    ./programs/starship.nix
  ];
}
