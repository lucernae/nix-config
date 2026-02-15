{ config, pkgs, lib, ... }:
let
  homedir = config.programs.gpg.homedir;
in
with pkgs;
{
  home.file."${homedir}/gpg-agent.conf".text = ''
    # Timeout for cached passphrases (24 hours)
    pinentry-timeout 86400

    # Enable SSH support for gpg-agent to act as ssh-agent
    enable-ssh-support

    # Cache SSH keys without requiring a passphrase to protect them
    # The keys are stored unencrypted in gpg-agent's memory
    default-cache-ttl-ssh 86400
    max-cache-ttl-ssh 86400

    # Disable TTY prompts to force graphical pinentry for all operations
    # This prevents the terminal prompt from appearing before the graphical dialog
    no-allow-external-cache
    allow-loopback-pinentry
  '' +
  # Use pinentry-kwallet on Linux - integrates with KWallet on KDE Plasma
  # This provides graphical password prompts that can store passwords in KWallet
  (lib.strings.optionalString stdenv.isLinux ''
    pinentry-program /run/current-system/sw/bin/pinentry-kwallet
  '') +
  # Use pinentry-mac on macOS
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
