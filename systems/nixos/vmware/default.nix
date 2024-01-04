{ config, pkgs, home-manager, ... }:
{
  imports = [
    # vmware.guest module overrides
    # ../../../modules/vmware-guests.nix
    # ../../../modules/real-vnc-viewer/default.nix
    # Include the results of the hardware scan.
    # ./hardware-configuration.nix
  ];

  nix = {
    buildMachines = [
      {
        hostName = "aarch64-darwin-builder";
        systems = [ "aarch64-darwin" "x86_64-darwin" ];
        maxJobs = 1;
        speedFactor = 2;
      }
      {
        hostName = "linux-builder";
        systems = [ "x86_64-linux" "aarch64-linux" ];
        maxJobs = 1;
        speedFactor = 2;
      }
    ];
    distributedBuilds = true;
    settings.trusted-users = [
      "@admin"
      "@wheel"
    ];
    settings.builders-use-substitutes = false;
    settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
    settings.extra-platforms = [
      "x86_64-darwin"
      "aarch64-darwin"
    ];
    # package = nixpkgs-unstable.nix;
  };

  users.users.vmware = {
    name = "vmware";
    home = "/home/vmware";
    shell = pkgs.zsh;
  };

  # # List packages installed in system profile. To search by name, run:
  # # $ nix-env -qaP | grep wget
  environment.systemPackages =
    [
      # pkgs.vim
      # pkgs.zsh
      # pkgs.bash
      pkgs.home-manager
      pkgs.tailscale
      pkgs.open-vm-tools
      pkgs.xdg-utils
    ];

  # nix.package = pkgs.nix;

  programs.zsh.enable = true; # default shell on catalina

  virtualisation.vmware.guestCustom = {
    enable = true;
    headless = false;
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  fonts.fontDir.enable = true;
  fonts.packages = with pkgs; [
    jetbrains-mono
    (nerdfonts.override { fonts = [ "FiraCode" "DroidSansMono" ]; })
  ];

  # # `home-manager` config
  # # home-manager.useGlobalPkgs = true;
  # # home-manager.useUserPackages = true;
  # # home-manager.users.recalune = import ./home.nix;

  # system.activationScripts.fixZshPermissions = ''
  #   compaudit | xargs sudo chown root:admin
  # '';
  # system.activationScripts.restartGPGAgent = ''
  #   pkill gpg-agent
  # '';

  custom.real-vnc-viewer.enable = true;

  # # This value determines the NixOS release from which the default
  # # settings for stateful data, like file locations and database versions
  # # on your system were taken. It‘s perfectly fine and recommended to leave
  # # this value at the release version of the first install of this system.
  # # Before changing this value read the documentation for this option
  # # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  # system.stateVersion = "22.11"; # Did you read the comment?
}
