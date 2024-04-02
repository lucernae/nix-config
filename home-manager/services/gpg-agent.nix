{ config, pkgs, ... }:
let
  homedir = config.programs.gpg.homedir;
in
with pkgs;
{
  home.file."${homedir}/gpg-agent.conf".text = ''
    pinentry-timeout 86400
  '' +
  # commented out temporarily because we are testing custom pinentry
  #   (lib.strings.optionalString stdenv.isDarwin ''
  #   pinentry-program ${pinentry_mac}/Applications/pinentry-mac.app/Contents/MacOS/pinentry-mac
  # '');
  # commented out, this is for local settings
  # (lib.strings.optionalString stdenv.isDarwin ''
  #   pinentry-program /Users/recalune/WorkingDir/github/lucernae/pinentry-box/pinentry-box/result/bin/pinentry-box
  # '');
  (lib.strings.optionalString stdenv.isDarwin ''
    pinentry-program ${pkgs.pinentry-box}/bin/pinentry-box
  '');

  services.gpg-agent = {
    enable = stdenv.isLinux;
    enableZshIntegration = true;
    pinentryFlavor = "qt";
  };
}
