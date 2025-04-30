{
  description = "Recalune's systems";

  inputs = {
    # for nixpkgs
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.11";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    # for mac setup using nix-darwin
    darwin.url = "github:lnl7/nix-darwin/master";
    darwin.inputs.nixpkgs.follows = "nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    # home manager
    home-manager.url = "github:nix-community/home-manager/release-24.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    # devenv
    devenv.url = "github:cachix/devenv/latest";
    # devshell
    devshell.url = "github:numtide/devshell";
    devshell.inputs.nixpkgs.follows = "nixpkgs-unstable";
    # VS Code Nix Community
    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
    # Pinentry-Box
    pinentry-box.url = "github:lucernae/pinentry-box?dir=pinentry-box";
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
    homebrew-lizardbyte = {
      url = "github:LizardByte/homebrew-homebrew";
      flake = false;
    };
    homebrew-zeek = {
      url = "github:zeek/homebrew-zeek";
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
    , devshell
    , nix-vscode-extensions
    , pinentry-box
    , nix-homebrew
    , homebrew-core
    , homebrew-bundle
    , homebrew-cask
    , homebrew-cask-drivers
    , homebrew-cask-fonts
    , homebrew-apple
    , homebrew-lizardbyte
    , homebrew-zeek
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
              allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) [
                "vscode-extension-github-codespaces"
              ];
              allowUnsupportedSystem = true;
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
                pinentry-box = pinentry-box.packages.${system}.pinentry_box;
                pinentry-box-cli = pinentry-box.packages.${system}.pinentry_box_cli;
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

          isDarwin = system: builtins.elem system [
            flake-utils.lib.system.x86_64-darwin
            flake-utils.lib.system.aarch64-darwin
          ];

          isLinux = system: builtins.elem system [
            flake-utils.lib.system.x86_64-linux
            flake-utils.lib.system.aarch64-linux
          ];
        in
        {
          formatter = nixpkgs.legacyPackages.${system}.nixpkgs-fmt;
          packages =
            {
              darwinConfigurations =
                if isDarwin system then rec {
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
                            "zeek/homebrew-zeek" = homebrew-zeek;
                            "LizardByte/homebrew-homebrew" = homebrew-lizardbyte;
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
                } else { };

              nixosConfigurations =
                if isLinux system then rec {
                  vmware = nixosSystem {
                    # system = "aarch64-linux";
                    inherit system;
                    modules = attrValues self.nixosModules ++ [
                      # hardware config
                      ./hardware/vmware-${system}.nix
                      # vmware.guest module overrides
                      ./modules/vmware-guests.nix
                      # nixos config
                      ./systems/nixos/vmware
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

                  # to build: nix build github:lucernae/nix-config#nixosConfigurations.raspberry-pi_3.config.system.build.sdImage
                  raspberry-pi_3 = nixosSystem {
                    system = "aarch64-linux";
                    modules = attrValues self.nixosModules ++ [
                      "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64-installer.nix"
                      ./systems/nixos/raspi/configuration.nix
                    ];
                  };
                } else { };
            };

          # extra darwinModules not yet available in upstreams
          darwinModules = {
            # nix-serve =
          };

          # extra nixosModules not yet available in upstreams
          nixosModules = { };

          # devshell for cli shortcuts
          devShells.default =
            let
              pkgs = import nixpkgs {
                inherit system;
                overlays = [ devshell.overlays.default ];
              };
            in
            pkgs.devshell.mkShell {
              name = "nix-config";
              commands = [
                {
                  name = "pre-commit";
                  package = pkgs.pre-commit;
                }
                {
                  name = "pcr";
                  help = "pre-commit run --all-files";
                  command = "pre-commit run --all-files";
                }
                {
                  name = "flake-update";
                  help = "run nix brew update";
                  command = "nix flake lock --update-input $@";
                }
              ];
            };
        }
      );
}
