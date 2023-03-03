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
    onActivation = {
      autoUpdate = false;
      upgrade = false;
      # use zap if you want nix-darwin solely manages homebrew packages
      # cleanup = "zap";
    };
    taps = [
      "homebrew/core"
      "homebrew/cask"
      "homebrew/cask-fonts"
      "homebrew/cask-drivers"
    ];
    brews = [
      # "pinentry-mac"
      "jq"
      "yq"
      "mas"
      "dagger"
      "ykman"
      "thefuck"
    ];
    masApps = {
      Xcode = 497799835;
      # We prefer to use Tailscale nix-darwin modules, so we comment this out
      # Tailscale = 1475387142;
      Bitwarden = 1352778147;
      WhatsAppWeb = 1147396723;
      SlackDesktop = 803453959;
      OneDrive = 823766827;
    };
    casks = [
      "fig"
      "cron"
      "signal"
      "discord"
      # "visual-studio-code" maintained by home-manager
      "docker"
      "firefox"
      "microsoft-edge"
      "diffmerge"
      "db-browser-for-sqlite"
      "jetbrains-toolbox"
      "github"
      "google-drive"
      "vmware-fusion"
      "obs"
      "rectangle"
      "elgato-game-capture-hd"
      "steam"
    ];
  };

  fonts.fontDir.enable = true;
  fonts.fonts = with pkgs; [
    jetbrains-mono
    (nerdfonts.override { fonts = [ "FiraCode" "DroidSansMono" ]; })
  ];

  # `home-manager` config
  # home-manager.useGlobalPkgs = true;
  # home-manager.useUserPackages = true;
  # home-manager.users.recalune = import ./home.nix;

  system.activationScripts.fixZshPermissions = pkgs.runCommand ''
    compaudit | xargs sudo chown root:admin
  '';
  system.activationScripts.restartGPGAgent = pkgs.runCommand ''
    pkill gpg-agent
  '';

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;
}
