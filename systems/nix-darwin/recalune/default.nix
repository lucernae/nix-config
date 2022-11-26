{ config, pkgs, home-manager, ... }:
{
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

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages =
    [
      # pkgs.vim
      # pkgs.zsh
      # pkgs.bash
      pkgs.home-manager
      pkgs.tailscale
    ];

  # Use a custom configuration.nix location.
  # $ darwin-rebuild switch -I darwin-config=$HOME/.config/nixpkgs/darwin/configuration.nix
  # environment.darwinConfig = "$HOME/.config/nixpkgs/darwin/configuration.nix";

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;
  services.tailscale.enable = true;
  # nix.package = pkgs.nix;

  # Create /etc/zshrc that loads the nix-darwin environment.
  programs.zsh.enable = true; # default shell on catalina
  # programs.fish.enable = true;

  users.users.recalune = {
    name = "recalune";
    home = "/Users/recalune";
    shell = pkgs.zsh;
  };

  # environment.pathsToLink = [
  #   "/usr/share/zsh"
  # ];

  security.pam.enableSudoTouchIdAuth = pkgs.stdenv.isDarwin;

  homebrew = {
    enable = pkgs.stdenv.isDarwin;
    onActivation.upgrade = false;
    brews = [
      "pinentry-mac"
      "jq"
      "yq"
      "mas"
      "dagger"
    ];
    casks = [
      "fig"
      "cron"
      # "visual-studio-code" maintained by home-manager
      "docker"
    ];
  };

  fonts.fontDir.enable = true;
  fonts.fonts = with pkgs; [
    jetbrains-mono
    nerdfonts
  ];

  # `home-manager` config
  # home-manager.useGlobalPkgs = true;
  # home-manager.useUserPackages = true;
  # home-manager.users.recalune = import ./home.nix;

  system.activationScripts.fixZshPermissions = pkgs.runCommand ''
    compaudit | xargs sudo chown root:admin
  '';

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;
}
