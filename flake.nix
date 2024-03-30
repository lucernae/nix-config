{
  description = "Recalune's systems";

  inputs = {
    # for nixpkgs
    nixpkgs-stable.url = github:nixos/nixpkgs/nixpkgs-22.05-darwin;
    nixpkgs.url = github:NixOS/nixpkgs/nixpkgs-unstable;
    nixpkgs-unstable.url = github:NixOS/nixpkgs/nixpkgs-unstable;
    # for mac setup using nix-darwin
    darwin.url = github:lnl7/nix-darwin/master;
    darwin.inputs.nixpkgs.follows = "nixpkgs-unstable";
    flake-utils.url = github:numtide/flake-utils;
    # home manager
    home-manager.url = github:nix-community/home-manager;
    home-manager.inputs.nixpkgs.follows = "nixpkgs-unstable";
    # devenv
    devenv.url = "github:cachix/devenv/latest";
    # VS Code Nix Community
    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
    # nix-homebrew
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    # nix-homebrew tap
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-bundle = {
      url = "github:homebrew/homebrew-bundle";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    homebrew-cask-drivers = {
      url = "github:homebrew/homebrew-cask-drivers";
      flake = false;
    };
    homebrew-cask-fonts = {
      url = "github:homebrew/homebrew-cask-fonts";
      flake = false;
    };
    homebrew-apple = {
      url = "github:apple/homebrew-apple";
      flake = false;
    };
  };

  outputs =
    { self
    , darwin
    , nixpkgs
    , flake-utils
    , home-manager
    , devenv
    , nix-vscode-extensions
    , nix-homebrew
    , homebrew-core
    , homebrew-bundle
    , homebrew-cask
    , homebrew-cask-drivers
    , homebrew-cask-fonts
    , homebrew-apple
    , ...
    }@inputs:
    let
      inherit (darwin.lib) darwinSystem;
      inherit (nixpkgs.lib) nixosSystem;
      inherit (inputs.nixpkgs.lib) attrValues makeOverridable optionalAttrs singleton;
    in
    flake-utils.lib.eachSystem [
      flake-utils.lib.system.x86_64-linux
      flake-utils.lib.system.x86_64-darwin
      flake-utils.lib.system.aarch64-darwin
      flake-utils.lib.system.aarch64-linux
    ]
      (
        system:
        let
          # for nixpkgs configuration
          nixpkgsConfig = {
            config = {
              allowUnfree = true;
            };
            overlays = attrValues overlays ++ [
              (
                # For x86 packages that don't have aarch64 M1 support yet
                final: prev: (optionalAttrs (system == flake-utils.lib.system.aarch64-darwin) {
                  #   inherit (final.pkgs-x86)
                  #     vim
                })
              )
              (final: prev: {
                nix-vscode-extensions = nix-vscode-extensions.extensions.${system};
              })
            ];
          };

          # overlays config
          overlays = {
            apple-silicon = final: prev: optionalAttrs (system == flake-utils.lib.system.aarch64-darwin) {
              # For x86 packages that don't have aarch64 M1 support yet
              pkgs-x86 = import inputs.nixpkgs {
                system = "x86_64-darwin";
                inherit (nixpkgsConfig) config;
              };
            };
          };
        in
        {
          formatter = nixpkgs.legacyPackages.${system}.nixpkgs-fmt;
          packages =
            {
              darwinConfigurations = rec {
                recalune = darwinSystem {
                  inherit system;
                  modules = attrValues self.darwinModules ++ [
                    # modules
                    # ./services/nix-serve
                    nix-homebrew.darwinModules.nix-homebrew
                    {
                      nix-homebrew = {
                        # Install Homebrew under the default prefix
                        enable = true;

                        # Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
                        enableRosetta = true;

                        # User owning the Homebrew prefix
                        user = "recalune";

                        # taps
                        taps = {
                          "homebrew/homebrew-core" = homebrew-core;
                          "homebrew/homebrew-bundle" = homebrew-bundle;
                          "homebrew/homebrew-cask" = homebrew-cask;
                          "homebrew/homebrew-cask-drivers" = homebrew-cask-drivers;
                          "homebrew/homebrew-cask-fonts" = homebrew-cask-fonts;
                          "apple/homebrew-apple" = homebrew-apple;
                        };

                        # Automatically migrate existing Homebrew installations
                        autoMigrate = true;
                      };
                    }

                    # nix-darwin configuration
                    ./systems/nix-darwin/recalune
                    # home-manager
                    home-manager.darwinModules.home-manager
                    {
                      nixpkgs = nixpkgsConfig;
                      # `home-manager` config
                      home-manager.useGlobalPkgs = true;
                      home-manager.useUserPackages = true;
                      home-manager.users.recalune = import ./home-manager/recalune.nix;

                      # pass to home configuration
                      home-manager.extraSpecialArgs = {
                        inherit (devenv.packages.${system}) devenv;
                      };
                    }
                    # tailscale
                    # ./services/tailscale
                  ];
                  # inputs = { inherit darwin nixpkgs; };
                  inputs = { inherit darwin; };
                };

                maul = darwinSystem {
                  inherit system;
                  modules = attrValues self.darwinModules ++ [
                    # nix-darwin configuration
                    ./systems/nix-darwin/maul
                    # home-manager
                    home-manager.darwinModules.home-manager
                    {
                      nixpkgs = nixpkgsConfig;
                      # `home-manager` config
                      home-manager.useGlobalPkgs = true;
                      home-manager.useUserPackages = true;
                      home-manager.users.maul = import ./home-manager/maul.nix;
                    }
                    # tailscale
                    ./services/tailscale
                  ];
                  # inputs = { inherit darwin nixpkgs; };
                  inputs = { inherit darwin; };
                };
              };
              nixosConfigurations = rec {
                vmware = nixosSystem {
                  inherit system;
                  modules = attrValues self.nixosModules ++ [
                    # custom modules
                    ./modules/vmware-guests.nix
                    ./modules/real-vnc-viewer
                    # nixos config
                    ./systems/nixos/vmware/default.nix
                    ./systems/nixos/vmware/configuration.nix
                    # home-manager
                    home-manager.nixosModules.home-manager
                    {
                      nixpkgs = nixpkgsConfig;
                      # `home-manager` config
                      home-manager.useGlobalPkgs = true;
                      home-manager.useUserPackages = true;
                      home-manager.users.vmware = import ./home-manager/vmware.nix;

                      # pass to home configuration
                      home-manager.extraSpecialArgs = {
                        inherit (devenv.packages.${system}) devenv;
                      };
                    }
                    # tailscale
                    # ./services/tailscale
                  ];
                };

                raspberry-pi_3 = nixosSystem {
                  system = "aarch64-linux";
                  modules = attrValues self.nixosModules ++ [
                    "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
                    ./systems/nixos/raspi/configuration.nix
                  ];
                };
              };
            };

          # extra darwinModules not yet available in upstreams
          darwinModules = {
            # nix-serve = 
          };

          # extra nixosModules not yet available in upstreams
          nixosModules = { };
        }
      );
}
