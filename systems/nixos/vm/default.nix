{ config, pkgs, lib, ... }:
{
  imports = lib.optionals (builtins.pathExists ./hardware-configuration.nix) [
    ./hardware-configuration.nix
  ];

  nix = {
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
    settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

  # Bootloader configuration
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use latest kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Enable QEMU guest agent for better VM integration
  services.qemuGuest.enable = true;

  # Networking
  networking.hostName = "nixos-vm";
  networking.networkmanager.enable = true;

  # Set time zone
  time.timeZone = "Asia/Jakarta";

  # Internationalisation
  i18n.defaultLocale = "en_US.UTF-8";

  # Enable the X11 windowing system with lightweight desktop
  services.xserver.enable = true;

  # Use LightDM with Xfce for a lightweight desktop environment
  services.xserver.displayManager.lightdm.enable = true;
  services.xserver.desktopManager.xfce.enable = true;

  # Configure keymap
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS for printing
  services.printing.enable = true;

  # Enable sound with pipewire
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Define user account
  users.groups.vmuser = {
    gid = 1000;
  };
  users.users.vmuser = {
    isNormalUser = true;
    uid = 1000;
    description = "VM User";
    shell = pkgs.bash;
    extraGroups = [ "networkmanager" "wheel" "vmuser" ];
    # Set default password (change this after first login!)
    initialPassword = "vmuser";
  };

  # Enable automatic login for convenience
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "vmuser";

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # System packages - keep it minimal for VM
  environment.systemPackages = with pkgs; [
    vim
    wget
    curl
    git
    firefox
    htop
    neofetch
    tree
    unzip
    zip
  ];

  # Enable GnuPG agent
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  # Enable OpenSSH daemon
  services.openssh.enable = true;
  services.openssh.settings.PermitRootLogin = "no";
  services.openssh.settings.PasswordAuthentication = true;

  # Disable firewall for easier VM access (enable in production!)
  networking.firewall.enable = false;

  # Allow sudo without password for wheel group
  security.sudo.wheelNeedsPassword = false;

  # Enable SPICE agent for better VM performance when using SPICE
  services.spice-vdagentd.enable = true;

  # This value determines the NixOS release
  system.stateVersion = "25.11";
}
