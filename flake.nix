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
  };

  outputs = { self, darwin, nixpkgs, flake-utils, home-manager,  ... }@inputs:
    let
      inherit (darwin.lib) darwinSystem;
      inherit (inputs.nixpkgs.lib) attrValues makeOverridable optionalAttrs singleton;
    in
    flake-utils.lib.eachSystem [
      flake-utils.lib.system.x86_64-darwin
      flake-utils.lib.system.aarch64-darwin
    ]
      (
        system:
        let
          # for nixpkgs configuration
          nixpkgsConfig = {
            config = {
              allowUnfree = true;
            };
            overlays = attrValues overlays ++ singleton (
              # For x86 packages that don't have aarch64 M1 support yet
              final: prev: (optionalAttrs (system == flake-utils.lib.system.aarch64-darwin) {
                #   inherit (final.pkgs-x86)
                #     vim
              })
            );
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
                    }
                    # tailscale
                    ./services/tailscale
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
            };

          # extra darwinModules not yet available in upstreams
          darwinModules = { };
        }
      );
}
