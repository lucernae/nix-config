{ config, pkgs, ... }:
{
    programs.gpg = {
      enable = true;
      package = pkgs.gnupg23;
      settings = {
        use-agent = true;
      };
    };
}