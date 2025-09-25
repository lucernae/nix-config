{ config, pkgs, ... }: {
  imports = [
    ./hardware-configuration.nix
    ./networking.nix # generated at runtime by nixos-infect
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  environment.systemPackages = with pkgs; [
    vim
    git
    curl
    wget
    nano
    bind
    kubectl
    kubernetes-helm
    #iptables
    tailscale
    #openvpn
    python3
    #nodejs
    #docker-compose
  ];

  programs.vim.defaultEditor = true;

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 80 ];
  };

  boot.binfmt.emulatedSystems = [ "x86_64-linux" ];

  boot.tmp.cleanOnBoot = true;
  zramSwap.enable = true;
  networking.hostName = "nix-linux-builder";
  networking.domain = "";
  services.openssh.enable = true;

  services.nix-serve = {
    enable = true;
    secretKeyFile = "/root/nix-serve/cache-priv-key.pem";
  };
  services.tailscale.enable = true;
  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    virtualHosts = {
      # ... existing hosts config etc. ...
      "nix-cache.maulana.id" = {
        locations."/".proxyPass = "http://${config.services.nix-serve.bindAddress}:${toString config.services.nix-serve.port}";
      };
    };
  };

  users.users.root.openssh.authorizedKeys.keys = [
    ''ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDqlXJv/noNPmZMIfjJguRX3O+Z39xeoKhjoIBEyfeqgKGh9JOv7IDBWlNnd3rHVnVPzB9emiiEoAJpkJUnWNBidL6vPYn13r6Zrt/2WLT6TiUFU026ANdqMjIMEZrmlTsfzFT+OzpBqtByYOGGe19qD3x/29nbszPODVF2giwbZNIMo2x7Ww96U4agb2aSAwo/oQa4jQsnOpYRMyJQqCUhvX8LzvE9vFquLlrSyd8khUsEVV/CytmdKwUUSqmlo/Mn7ge/S12rqMwmLvWFMd08Rg9NHvRCeOjgKB4EI6bVwF8D6tNFnbsGVzTHl7Cosnn75U11CXfQ6+8MPq3cekYr''
    ''ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCz2+R/ccmgzn9wRLx/cwdaPFOVrEwqR8sECyMlefyTpF9MWvselwNglhVBrgVSfNEo/o1XDhzZ04iGv28hVeakOBrl51BF1V5C6Q24y36lyM+8vOl/AtRxGDogN/FRoeeY25JNNm2/cZQEJxMeG23TWhNE1kc1sMfhJ4ozT3ZA971eKI3rp+6PpyR+3NuCL1qxZJiRj0j5cuJy69tEm4aCoG+kAhBeyNoC7VqF5CS3DncIBGgblL33pISBupOzXT8PqJVK/FeLrP08KgGqFsggRMz/v60TYReKHCL6RXR4JZ9GTU8YDEumeAd6p/ggiuOiFISunCvGcG3DNt/I2e5NIwZLkbYFls3C6OyoW3QuqoS5v2E9dJzER+bJEFdPpPJUYPQbf+49OQUtdNVrQwUPCKPtQ46FbhWMNS3hVRZJ7cH8hg/n+paqmsVFN4mNCX8QBFX9OEJDzwxszJ+7LebDgMHlbxwkaMrAsUF8EE93U+IqpeY3CbkSnti1fu45fys= vmware@vmware''
  ];
  system.stateVersion = "23.11";
}
