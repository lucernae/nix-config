{ config, pkgs, ... }:
let
    homedir = config.programs.gpg.homedir;
in
{
    home.file."${homedir}/gpg-agent.conf".text = ''
        pinentry-program /usr/local/bin/pinentry-mac
    '';
}