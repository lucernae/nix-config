{ config, pkgs, lib, ... }:
{
  imports = lib.optionals (builtins.pathExists ./hardware-configuration.nix) [
    ./hardware-configuration.nix
  ] ++ [
    ./gaming.nix
  ];

  nix = {
    distributedBuilds = false;
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

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use stable kernel for NVIDIA compatibility.
  boot.kernelPackages = pkgs.linuxPackages;

  # AMD CPU microcode updates
  hardware.cpu.amd.updateMicrocode = true;

  # Mount /home partition from sdc4
  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/446b935e-a5ff-425d-90ca-305d269bf70f";
    fsType = "ext4";
  };

  # NVIDIA drivers
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  networking.hostName = "red-fenrir";

  # Enable networking
  networking.networkmanager = {
    enable = true;
    # Use systemd-resolved for DNS
    dns = "systemd-resolved";
  };

  # Configure NetworkManager to ignore DHCP DNS
  environment.etc."NetworkManager/conf.d/dns.conf".text = ''
    [connection]
    ipv4.ignore-auto-dns=yes
    ipv6.ignore-auto-dns=yes
  '';

  # DNS configuration with DNS-over-TLS
  services.resolved = {
    enable = true;
    dnssec = "true";
    domains = [ "~." ];
    # Primary DNS servers (not just fallback)
    extraConfig = ''
      DNS=1.1.1.1 1.0.0.1 2606:4700:4700::1111 2606:4700:4700::1001
    '';
    fallbackDns = [ "1.1.1.1" "1.0.0.1" ];
    dnsovertls = "true";
  };

  # Enable Bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  # Set your time zone.
  time.timeZone = "Asia/Jakarta";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Define a user account. Don't forget to set a password with 'passwd'.
  users.groups.lucernae = {
    gid = 1000;
  };
  users.users.lucernae = {
    isNormalUser = true;
    uid = 1000;
    description = "lucernae";
    shell = pkgs.zsh;
    extraGroups = [ "networkmanager" "wheel" "docker" "lucernae" ];
    packages = with pkgs; [
      kdePackages.kate
    ];
  };

  # Install firefox.
  programs.firefox.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile.
  environment.systemPackages = with pkgs; [
    vim
    wget
    claude-code
    vscode
    kdePackages.filelight
    bitwarden-desktop
    git
    home-manager
    pciutils
    tailscale
    vlc
    kwalletcli
    pinentry-qt
    kdePackages.kwallet-pam
    kdePackages.ksshaskpass
    fastfetch

    # Network diagnostic tools
    bind          # dig, nslookup, host - DNS lookup tools
    inetutils     # ping, traceroute, ifconfig, netstat
    iproute2      # ip, ss - modern network utilities
    tcpdump       # Packet capture and analysis
    #wireshark     # GUI packet analyzer
    nmap          # Network scanner
    curl          # HTTP/HTTPS client
    netcat-gnu    # TCP/UDP testing tool
    mtr           # Network diagnostic tool (ping + traceroute)
    iftop         # Network bandwidth monitoring
    ethtool       # Ethernet device configuration
    iperf3        # Network performance testing
    whois         # Domain information lookup
    dnsutils      # Additional DNS utilities
  ];

  # Enable GnuPG agent with SSH support
  # This allows gpg-agent to act as ssh-agent and use KWallet for password prompts
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  programs.zsh.enable = true;
  programs.partition-manager.enable = true;

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = false;

  nixpkgs.config.allowUnsupportedSystem = true;

  services.tailscale.enable = true;

  security.sudo.wheelNeedsPassword = false;

  virtualisation.docker.enable = true;

  fonts.fontDir.enable = true;

  fonts.packages = with pkgs; [
    jetbrains-mono
    nerd-fonts.fira-code
    nerd-fonts.droid-sans-mono
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?
}
