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
    distributedBuilds = false;
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
      # pkgs.tailscale
      # pkgs.pinentry_mac
    ];

  # Use a custom configuration.nix location.
  # $ darwin-rebuild switch -I darwin-config=$HOME/.config/nixpkgs/darwin/configuration.nix
  # environment.darwinConfig = "$HOME/.config/nixpkgs/darwin/configuration.nix";

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;
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
  services.yabai = {
    enable = true;
    config = {
      window_placement = "second_child";
      layout = "bsp";
      top_padding = 16;
      bottom_padding = 16;
      left_padding = 16;
      right_padding = 16;
      window_gap = 16;
      mouse_follows_focus = "on";
      mouse_modifier = "alt";
      mouse_action1 = "move";
      mouse_action2 = "resize";
      mouse_drop_action = "swap";
    };
    extraConfig = ''
      yabai -m rule --add app="^System Settings" manage=off
      yabai -m rule --add app="^Raycast" manage=off
    '';
  };

  services.skhd = {
    enable = true;
    skhdConfig = ''
      # directional ijkl
      alt - k : yabai -m window --focus south
      alt - i : yabai -m window --focus north
      alt - j : yabai -m window --focus west
      alt - l : yabai -m window --focus east

      # directional awsd
      alt - s : yabai -m window --focus south
      alt - w : yabai -m window --focus north
      alt - a : yabai -m window --focus west
      alt - d : yabai -m window --focus east

      # display focus change
      alt - f : yabai -m display --focus west
      alt - g : yabai -m display --focus east
      # for alternating between display
      alt - h : yabai -m display --focus recent
      # immediate display targeting
      ctrl + alt - 1 : yabai -m display --focus 1
      ctrl + alt - 2 : yabai -m display --focus 2

      # rotate layout clockwise
      shift + alt - r : yabai -m space --rotate 270

      # flip along y-axis
      shift + alt - t : yabai -m space --mirror y-axis

      # flip along x-axis
      shift + alt - e : yabai -m space --mirror x-axis

      # toggle window float
      shift + alt - q : yabai -m window --toggle float --grid 4:4:1:1:2:2

      # maximize window
      shift + alt - c : yabai -m window --toggle zoom-fullscreen

      # balancing space
      shift + alt - h : yabai -m space --balance

      # swap windows
      shift + alt - k : yabai -m window --swap south
      shift + alt - i : yabai -m window --swap north
      shift + alt - j : yabai -m window --swap west
      shift + alt - l : yabai -m window --swap east
      
      # transfer windows
      ctrl + alt - k : yabai -m window --warp south
      ctrl + alt - i : yabai -m window --warp north
      ctrl + alt - j : yabai -m window --warp west
      ctrl + alt - l : yabai -m window --warp east

      # move window over spaces
      shift + alt - v : yabai -m window --space prev
      shift + alt - b : yabai -m window --space next

      # move window to space
      shift + alt - 1 : yabai -m window --space 1
      shift + alt - 2 : yabai -m window --space 2
      shift + alt - 3 : yabai -m window --space 3
      shift + alt - 4 : yabai -m window --space 4
      shift + alt - 5 : yabai -m window --space 5
      shift + alt - 6 : yabai -m window --space 6
      shift + alt - 7 : yabai -m window --space 7
      shift + alt - 8 : yabai -m window --space 8
      shift + alt - 9 : yabai -m window --space 9

      # start stop yabai
      ctrl + alt - q : launchctl stop org.nixos.yabai
      ctrl + alt - s : launchctl start org.nixos.yabai

      # apply skhd config
      ctrl + alt - r : launchctl stop org.nixos.skhd; launchctl start org.nixos.skhd;
    '';
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
      # WhatsAppWeb = 1147396723;
      WhatsAppMessenger = 310633997;
      SlackDesktop = 803453959;
      OneDrive = 823766827;
      Line = 539883307;
    };
    casks = [
      "fig"
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
      # no casks for homerow yet.
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
