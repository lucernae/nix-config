# minimal nix-darwin configuration to bootstrap an installer
{ config, pkgs, home-manager, ... }:
{
  nix = {
    settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
    settings.extra-platforms = [
      "x86_64-darwin"
      "aarch64-darwin"
    ];
  };


  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages =
    [
      pkgs.vim
      pkgs.bash
    ];

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;
  system.stateVersion = 4;
}
