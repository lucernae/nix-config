{ config, pkgs, home-manager, ... }:
{
  imports = [
    # vmware.guest module overrides
    ./modules/vmware-guests.nix
  ]

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

  disabledModules = [
    "virtualisation/vmware-guest.nix"
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";

  boot.binfmt.emulatedSystems = [ "x86_64-linux" ];

  hardware.video.hidpi.enable = true;

  # Share our host filesystem
  # See: https://kb.vmware.com/s/article/60262
  fileSystems."/host" = {
    fsType = "fuse./run/current-system/sw/bin/vmhgfs-fuse";
    device = ".host:/";
    options = [
      "umask=022"
      "uid=${builtins.toString config.users.users.vmware.uid}"
      "gid=${builtins.toString config.users.groups.vmware.gid}"
      "allow_other"
      "auto_unmount"
      "defaults"
    ];
  };

  networking.hostName = "vmware"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Asia/Jakarta";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "id_ID.UTF-8";
    LC_IDENTIFICATION = "id_ID.UTF-8";
    LC_MEASUREMENT = "id_ID.UTF-8";
    LC_MONETARY = "id_ID.UTF-8";
    LC_NAME = "id_ID.UTF-8";
    LC_NUMERIC = "id_ID.UTF-8";
    LC_PAPER = "id_ID.UTF-8";
    LC_TELEPHONE = "id_ID.UTF-8";
    LC_TIME = "id_ID.UTF-8";
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the KDE Plasma Desktop Environment.
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;

  # Configure keymap in X11
  services.xserver = {
    layout = "us";
    xkbVariant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.groups.vmware = {
    gid = 1000;
  };
  users.users.vmware = {
    isNormalUser = true;
    uid = 1000;
    description = "vmware";
    shell = pkgs.zsh;
    extraGroups = [ "networkmanager" "wheel" "docker" "vmware" ];
    packages = with pkgs; [
      firefox
      kate
      #  thunderbird
    ];
  };

  # Enable automatic login for the user.
  services.xserver.displayManager.autoLogin.enable = true;
  services.xserver.displayManager.autoLogin.user = "vmware";

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # virtualisation.vmware.guest.enable = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    #  wget
    pciutils
    tailscale
    open-vm-tools
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };


  # programs.vim = {
  #   enable = true;
  #   enableSensible = true;
  #   plugins = [
  #     {
  #         names = [ "vim-nix" ];
  #     }
  #   ];
  # };

  # services.gnome.gnome-keyring.enable = true;

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  nixpkgs.config.allowUnsupportedSystem = true;


  services.tailscale.enable = true;

  # environment.pathsToLink = [
  #   "/usr/share/zsh"
  # ];

  security.sudo.wheelNeedsPassword = false;
  # security.pam.services.vmware.enableGnomeKeyring = true;
  virtualisation.vmware.guest.enable = true;
  virtualisation.docker.enable = true;

  fonts.fontDir.enable = true;
  fonts.fonts = with pkgs; [
    jetbrains-mono
    (nerdfonts.override { fonts = [ "FiraCode" "DroidSansMono" ]; })
  ];

  # `home-manager` config
  # home-manager.useGlobalPkgs = true;
  # home-manager.useUserPackages = true;
  # home-manager.users.recalune = import ./home.nix;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.11"; # Did you read the comment?
}
