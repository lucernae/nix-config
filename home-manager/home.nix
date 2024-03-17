{ config, pkgs, lib, ... }:
{
  home.packages = with pkgs; [
    iconv
    htop
    zsh
    oh-my-zsh
    git
    vim
    gh
    colima
    nixd
    act
    comma
    bitwarden-cli
    bws
    elan
  ] ++ [
    # programming languages related
    go
    wasmtime
    python3
    python3Packages.pip
    python3Packages.virtualenv
    cmake
    yarn
    poetry
  ] ++ (
    lib.optionals stdenv.isDarwin [
      pinentry-box-cli
    ]
  );

  home.file.scripts = {
    enable = true;
    source = ./scripts;
    target = "./.scripts";
    recursive = false;
  };

  # NodeJS global settings
  home.sessionPath = [
    "$HOME/.npm-global"
  ];

  home.file.".npmrc" = {
    enable = true;
    text = ''
      prefix=$HOME/.npm-global
    '';
    target = ".npmrc";
  };

  home.activation.node-npm-global = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p $HOME/.npm-global $HOME/.npm-global/lib $HOME/.npm-global/bin
  '';

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
