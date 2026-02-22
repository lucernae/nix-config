{ config, pkgs, lib, ... }:
{
  # NixOS wants to enable GRUB by default
  boot.loader.grub.enable = false;
  # Enables the generation of /boot/extlinux/extlinux.conf
  boot.loader.generic-extlinux-compatible.enable = true;

  # !!! Set to specific linux kernel version
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Disable ZFS on kernel 6
  boot.supportedFilesystems = lib.mkForce [
    "vfat"
    "xfs"
    "cifs"
    "ntfs"
  ];

  boot.loader = {
    efi.canTouchEfiVariables = false;
    #grub = {
    # enable = true;
    #efiSupport = true;
    #efiInstallAsRemovable = true;
    #device = "nodev";
    #};
  };

  # !!! Needed for the virtual console to work on the RPi 3, as the default of 16M doesn't seem to be enough.
  # If X.org behaves weirdly (I only saw the cursor) then try increasing this to 256M.
  # On a Raspberry Pi 4 with 4 GB, you should either disable this parameter or increase to at least 64M if you want the USB ports to work.
  boot.kernelParams = [ "cma=256M" ];

  # File systems configuration for using the installer's partition layout
  fileSystems = {
    # Prior to 19.09, the boot partition was hosted on the smaller first partition
    # Starting with 19.09, the /boot folder is on the main bigger partition.
    # The following is to be used only with older images.
    /*
      "/boot" = {
      device = "/dev/disk/by-label/NIXOS_BOOT";
      fsType = "vfat";
      };
    */
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
    };
    "/boot/firmware" = {
      device = "/dev/disk/by-label/FIRMWARE";
      fsType = "vfat";
    };
  };

  # !!! Adding a swap file is optional, but strongly recommended!
  swapDevices = [{ device = "/swapfile"; size = 1024; }];

  # systemPackages

  services.code-server.enable = true;
  environment.systemPackages = with pkgs; [
    vim
    curl
    wget
    nano
    bind
    kubectl
    helm
    iptables
    openvpn
    htop

    # Remote desktop solutions
    wayvnc # VNC server for Wayland\
    python3
    nodejs
    docker-compose

    # Niri Wayland compositor essentials
    novnc
    python3Packages.websockify # Browser-based VNC access
    xorg.libXcursor
    xorg.libXrandr
    xorg.libXi
    xorg.libX11 # X11 libs needed by Niri via winit
    ghostty
    fuzzel
    waybar
    mako
    grim
    slurp
  ];

  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "yes";
  };
  services.tailscale = {
    enable = true;
  };

  # Some sample service.
  # Use dnsmasq as internal LAN DNS resolver.
  services.dnsmasq = {
    enable = false;
    settings = {
      interface = "wlan0";
      bind-interfaces = true;
      dhcp-auhtoritative = false;
      dhcp-range = [
        "192.168.1.100,192.168.1.255,1d"
      ];
      #settings = {
      servers = config.networking.nameservers ++ [ "8.8.8.8" "8.8.4.4" "1.1.1.1" ];
      #dhcp-host = [ "192.168.
      address = [
        "/wlan.nixpi.internal/192.168.12.1"
      ];
    };
  };

  # services.openvpn = {
  #     # You can set openvpn connection
  #     servers = {
  #       privateVPN = {
  #         config = "config /home/nixos/vpn/privatvpn.conf";
  #       };
  #     };
  # };

  programs.zsh = {
    enable = true;
    ohMyZsh = {
      enable = true;
      theme = "bira";
    };
  };


  virtualisation.docker.enable = true;
  # Enable Niri Wayland compositor
  programs.niri.enable = true;

  networking.firewall.enable = false;


  # WiFi
  hardware = {
    enableRedistributableFirmware = true;
    firmware = [ pkgs.wireless-regdb ];
  };
  # Networking
  networking = {
    # useDHCP = true;
    interfaces.wlan0 = {
      #useDHCP = false;
      #ipv4.addresses = [{
      # I used static IP over WLAN because I want to use it as local DNS resolver
      #address = "192.168.1.4";
      #prefixLength = 24;
      #}];
    };
    interfaces.eth0 = {
      useDHCP = true;
      # I used DHCP because sometimes I disconnect the LAN cable
      #ipv4.addresses = [{
      #address = "192.168.1.7";
      #prefixLength = 24;
      #}];
    };

    # Enabling WIFI
    wireless.enable = true;
    wireless.interfaces = [ "wlan0" ];
    # If you want to connect also via WIFI to your router
    # wireless.networks."<SSID>".psk = "<ssid-password>";
    # You can set default nameservers
    # nameservers = [ "192.168.100.3" "192.168.100.4" "192.168.100.1" ];
    # You can set default gateway
    #defaultGateway = {
    #  address = "192.168.1.1";
    #  interface = "eth0";
    #};
  };

  services.create_ap = {
    enable = true;
    settings = {
      GATEWAY = "192.168.2.1";
      #DHCP_DNS = "gateway";
      INTERNET_IFACE = "eth0";
      WIFI_IFACE = "wlan0";
      SSID = "nixos-pi";
      PASSPHRASE = "<your-password>";
      #SHARE_METHOD = "bridge";
    };
  };

  # forwarding
  boot.kernel.sysctl = {
    "net.ipv4.conf.all.forwarding" = true;
    "net.ipv6.conf.all.forwarding" = true;
    "net.ipv4.tcp_ecn" = true;
  };

  # Nix settings for distributed builds and binary caches
  nix = {
    # Remote builder configuration
    buildMachines = [
      {
        hostName = "nix-linux-builder";
        systems = [ "aarch64-linux" ];
        maxJobs = 8;
        speedFactor = 2;
        supportedFeatures = [ "big-parallel" "benchmark" ];
      }
    ];

    # Enable distributed builds
    distributedBuilds = true;

    settings = {
      # Binary cache substituters
      substituters = [
        "https://cache.nixos.org"
        "https://nix-cache.maulana.id"
      ];

      # Trusted public keys for binary caches
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-cache.maulana.id:PYgqkzRGbXkj3S9i/81ripyCBt1QULks55VuOeJ8FHo="
      ];

      # Allow remote builders to use substituters
      builders-use-substitutes = true;

      # Enable Nix flakes and new nix command
      experimental-features = [ "nix-command" "flakes" ];
    };
  };

  # put your own configuration here, for example ssh keys:
  users.defaultUserShell = pkgs.zsh;
  users.mutableUsers = true;
  users.groups = {
    nixos = {
      gid = 1000;
      name = "nixos";
    };
  };
  users.users = {
    nixos = {
      uid = 1000;
      home = "/home/nixos";
      name = "nixos";
      group = "nixos";
      shell = pkgs.zsh;
      extraGroups = [ "wheel" "docker" ];
      isNormalUser = true;
      # you should change this default password later
      initialPassword = "nixoschangeme";
      # alternatively use initialHashedPassword by filling in mkpasswd hashed string
      # initialHashedPassword = "";
    };
  };
  users.extraUsers.root.openssh.authorizedKeys.keys = [
    # This is my public key
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDqlXJv/noNPmZMIfjJguRX3O+Z39xeoKhjoIBEyfeqgKGh9JOv7IDBWlNnd3rHVnVPzB9emiiEoAJpkJUnWNBidL6vPYn13r6Zrt/2WLT6TiUFU026ANdqMjIMEZrmlTsfzFT+OzpBqtByYOGGe19qD3x/29nbszPODVF2giwbZNIMo2x7Ww96U4agb2aSAwo/oQa4jQsnOpYRMyJQqCUhvX8LzvE9vFquLlrSyd8khUsEVV/CytmdKwUUSqmlo/Mn7ge/S12rqMwmLvWFMd08Rg9NHvRCeOjgKB4EI6bVwF8D6tNFnbsGVzTHl7Cosnn75U11CXfQ6+8MPq3cekYr lucernae@lombardia-N43SM"
  ];

  fonts.fontDir.enable = true;

  fonts.packages = with pkgs; [
    jetbrains-mono
    nerd-fonts.fira-code
    nerd-fonts.droid-sans-mono
  ];

  system.stateVersion = "23.05";


  # Set hostname to match flake configuration
  networking.hostName = "nixos-pi";

  # Auto-start Niri on boot with greetd
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.niri}/bin/niri-session";
        user = "nixos";
      };
    };
  };

  # WayVNC service for remote desktop access

  # noVNC for browser-based VNC access
  systemd.services.novnc = {
    description = "noVNC WebSocket proxy for WayVNC";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.python3Packages.websockify}/bin/websockify --web=${pkgs.novnc} 6080 localhost:5900";
      Restart = "on-failure";
      User = "nobody";
      Group = "nogroup";
    };
  };

  # Import Wayland environment variables for systemd user services
  systemd.user.services.import-wayland-env = {
    description = "Import Wayland environment to systemd";
    wantedBy = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.writeShellScript "import-wayland-env" ''
        # Wait for Wayland socket
        for i in {1..20}; do
          if [ -S "$XDG_RUNTIME_DIR/wayland-0" ] || [ -S "$XDG_RUNTIME_DIR/wayland-1" ]; then
            # Socket found, export to systemd
            if [ -z "$WAYLAND_DISPLAY" ]; then
              # Try to detect socket name
              for socket in wayland-0 wayland-1; do
                if [ -S "$XDG_RUNTIME_DIR/$socket" ]; then
                  export WAYLAND_DISPLAY=$socket
                  break
                fi
              done
            fi
            systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
            ${pkgs.dbus}/bin/dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
            exit 0
          fi
          sleep 0.5
        done
        echo "Wayland socket not found after 10 seconds"
        exit 1
      ''}";
    };
  };

  systemd.user.services.wayvnc = {
    description = "WayVNC - VNC server for Wayland";
    wantedBy = [ "graphical-session.target" ];
    after = [ "graphical-session.target" "import-wayland-env.service" ];
    requires = [ "import-wayland-env.service" ];
    partOf = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.wayvnc}/bin/wayvnc -o HDMI-A-1 -L trace 0.0.0.0 5900";
      Restart = "on-failure";
      RestartSec = "2s";
    };
  };
}

