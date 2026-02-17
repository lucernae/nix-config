{ config, pkgs, lib, ... }:

let
  gpgForwardingEnabled = config.myConfig.gpgForwarding.enable or false;
in
{
  programs.gpg = {
    enable = true;
    package = pkgs.gnupg;
    settings = {
      use-agent = true;
      no-autostart = lib.mkDefault gpgForwardingEnabled;
    };
  };
}
