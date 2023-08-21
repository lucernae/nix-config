{ config, pkgs, ... }:
{
  home.packages = with pkgs; [
    htop
    zsh
    oh-my-zsh
    git
    # vim # declared as programs.vim
    gh
    colima
    act
  ] ++ (lib.optionals stdenv.isDarwin [
    pinentry_mac
    bitwarden
    bitwarden-cli
  ])
  ++ (lib.optionals stdenv.isLinux [ kgpg kwalletcli ]);

  home.file.scripts = {
    enable = true;
    source = ./scripts;
    target = "./.scripts";
    recursive = false;
  };

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "22.05";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
