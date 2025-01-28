{ config, pkgs, home-manager, ... }:
{
  nix = {
    settings.trusted-users = [
      "@admin"
      "@wheel"
    ];
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

  users.users.maul = {
    name = "maul";
    home = "/Users/maul";
  };

  security.pam.enableSudoTouchIdAuth = pkgs.stdenv.isDarwin;

  homebrew = {
    enable = pkgs.stdenv.isDarwin;
    onActivation.upgrade = false;
    brews = [
      "pinentry-mac"
      "jq"
      "yq"
      "mas"
    ];
    casks = [
      "cron"
    ];
  };

  # `home-manager` config
  # home-manager.useGlobalPkgs = true;
  # home-manager.useUserPackages = true;
  # home-manager.users.recalune = import ./home.nix;

  system.activationScripts.fixZshPermissions = pkgs.runCommand ''
    compaudit | xargs sudo chown root:admin
  '';
  system.activationScripts.restartGPGAgent = pkgs.runCommand ''
    pkill gpg-agent
  ''

    # Used for backwards compatibility, please read the changelog before changing.
    # $ darwin-rebuild changelog
    system.stateVersion = 4;
}
