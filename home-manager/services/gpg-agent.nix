{ config, pkgs, lib, ... }:
let
  homedir = config.programs.gpg.homedir;
in
with pkgs;
{
  home.file."${homedir}/gpg-agent.conf".text = ''
    pinentry-timeout 86400
  '' +
  # Use pinentry-kwallet on Linux for KWallet integration
  (lib.strings.optionalString stdenv.isLinux ''
    pinentry-program /run/current-system/sw/bin/pinentry-kwallet
  '') +
  # commented out temporarily because we are testing custom pinentry
  (lib.strings.optionalString stdenv.isDarwin ''
    pinentry-program ${pinentry_mac}/Applications/pinentry-mac.app/Contents/MacOS/pinentry-mac
  '');
  # commented out, this is for local settings
  # (lib.strings.optionalString stdenv.isDarwin ''
  #   pinentry-program /Users/recalune/WorkingDir/github/lucernae/pinentry-box/pinentry-box/result/bin/pinentry-box
  # '');
  #  (lib.strings.optionalString stdenv.isDarwin ''
  #    pinentry-program ${pkgs.pinentry-box}/bin/pinentry-box
  #  '');

  ## commented out because we uses systems level integration
  # services.gpg-agent = {
  #   enable = false;
  #   # enable = stdenv.isLinux;
  #   enableZshIntegration = true;
  #   pinentry.package = pkgs.pinentry-qt;
  #   # pinentry-qt should integrate with KWallet automatically on KDE Plasma
  # };
}
