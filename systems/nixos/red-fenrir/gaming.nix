{ config, pkgs, ... }:

{
  # Enable Steam with recommended settings
  programs.steam = {
    enable = true;

    # Open firewall ports for Steam Remote Play (optional)
    remotePlay.openFirewall = true;

    # Open firewall ports for Steam game servers (optional)
    dedicatedServer.openFirewall = true;

    # Enable gamescope session for Steam Deck-like experience (optional)
    gamescopeSession.enable = true;
  };

  # Enable GameMode for improved gaming performance
  # Games can request performance optimizations via gamemode
  programs.gamemode.enable = true;

  # Enable 32-bit graphics libraries support
  # Required for running 32-bit games and some Windows games via Proton
  hardware.graphics.enable32Bit = true;

  # Gaming-related system packages
  environment.systemPackages = with pkgs; [
    # Performance monitoring and overlay
    mangohud              # FPS and performance overlay for Vulkan/OpenGL games

    # Proton version management
    protonup-qt           # GUI tool to manage custom Proton versions (GE-Proton)

    # Additional game launchers
    lutris                # Open source gaming platform (supports Epic, GOG, etc.)
    heroic                # Epic Games and GOG launcher

    # Gaming compositor
    gamescope             # SteamOS session compositing window manager

    # Gamepad/controller support
    antimicrox            # Map keyboard and mouse to gamepad controls
  ];

  # Ensure gamemode is accessible to users
  programs.gamemode.settings = {
    general = {
      renice = 10;
    };

    # GPU performance settings (for NVIDIA)
    gpu = {
      apply_gpu_optimisations = "accept-responsibility";
      gpu_device = 0;
      nv_powermizer_mode = 1; # Maximum performance mode
    };
  };
}
