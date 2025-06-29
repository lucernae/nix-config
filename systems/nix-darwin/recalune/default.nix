{ config, pkgs, home-manager, ... }:
{
  imports = [
    # window manager
    ./yabai.nix
    # keyboard shortcut manager
    ./skhd.nix
    # macos defaults settings
    ./mac-defaults.nix
  ];
  nix = {
    enable = true;
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
    settings.substituters = pkgs.lib.optionals true [
      "http://nix-cache.maulana.id"
    ];
    settings.trusted-public-keys = pkgs.lib.optionals true [
      "nix-cache.maulana.id:PYgqkzRGbXkj3S9i/81ripyCBt1QULks55VuOeJ8FHo="
    ];
    settings.builders-use-substitutes = true;
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
      # pkgs.tailscale
      # pkgs.pinentry_mac
    ];

  # Use a custom configuration.nix location.
  # $ darwin-rebuild switch -I darwin-config=$HOME/.config/nixpkgs/darwin/configuration.nix
  # environment.darwinConfig = "$HOME/.config/nixpkgs/darwin/configuration.nix";

  # Auto upgrade nix package and the daemon service.
  launchd.daemons.nix-serve = {
    serviceConfig = {
      Label = "org.nixos.nix-serve";
      # Note that currently we are using x86_64-darwin because no aarch64-darwin system available
      ProgramArguments = [
        "/bin/sh"
        "-c"
        "NIX_SECRET_KEY_FILE=/Users/recalune/.ssh/cache-priv-key.pem /run/current-system/sw/bin/nix run github:edolstra/nix-serve#defaultPackage.x86_64-darwin -- --listen :5700"
      ];
      StandardErrorPath = "/tmp/nix-serve.err";
      StandardOutPath = "/tmp/nix-serve.out";
      RunAtLoad = true;
      KeepAlive = {
        SuccessfulExit = false;
      };
    };
  };
  # services.tailscale.enable = true;
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

  security.pam.services.sudo_local.touchIdAuth = pkgs.stdenv.isDarwin;

  homebrew = {
    enable = pkgs.stdenv.isDarwin;
    onActivation = {
      autoUpdate = false;
      upgrade = false;
      # use zap if you want nix-darwin solely manages homebrew packages
      # cleanup = "zap";
    };
    taps = [
      "homebrew/bundle"
      "homebrew/core"
      "homebrew/cask"
      "homebrew/cask-fonts"
      "homebrew/cask-drivers"
    ];
    brews = [
      "pinentry-mac"
      "jq"
      "yq"
      "mas"
      "dagger"
      "ykman"
      "thefuck"
      "opencv"
      "onnxruntime"
      "fswatch"
      # sunshine is still experimental in macos
      # "sunshine"
    ];
    masApps = {
      # App URL format
      # https://apps.apple.com/id/app/line/id539883307?mt=12
      Xcode = 497799835;
      # We prefer to use Tailscale nix-darwin modules, so we comment this out
      Tailscale = 1475387142;
      Bitwarden = 1352778147;
      WhatsAppMessenger = 310633997;
      SlackDesktop = 803453959;
      OneDrive = 823766827;
      Line = 539883307;
    };
    casks = [
      "notion-calendar"
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
      "keycastr"
      "raycast"
      "shortcat"
      "ghostty"
      #      "barrier"
      # no casks for homerow yet.
    ];
  };

  fonts.packages = with pkgs; [
    jetbrains-mono
    nerd-fonts.fira-code
    nerd-fonts.droid-sans-mono
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
