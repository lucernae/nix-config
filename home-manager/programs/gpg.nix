{ config, pkgs, ... }:
{
  programs.gpg = {
    enable = true;
    package = pkgs.gnupg;
    settings = {
      use-agent = true;
    };
  };
}
