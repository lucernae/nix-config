{ config, pkgs, ... }:
{
    programs.vim = {
      enable = true;
      plugins = with pkgs.vimPlugins; [
        vim-sensible
        vim-nix
      ];
    };
}