{ config, pkgs, ... }:
let
    homedir = config.programs.gpg.homedir;
in
with pkgs;
{
    home.file."${homedir}/gpg-agent.conf".text = ''
    '' + (lib.strings.optionalString stdenv.isDarwin ''
        pinentry-program /usr/local/bin/pinentry-mac
    '');

    services.gpg-agent.enable = stdenv.isLinux;
    services.gpg-agent.enableZshIntegration = true;
}