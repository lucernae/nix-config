{
  description = "Nix-Darwin minimal systems";

  inputs = {
    # for nixpkgs
    nixpkgs-stable.url = github:nixos/nixpkgs/nixpkgs-22.05-darwin;
    nixpkgs.url = github:NixOS/nixpkgs/nixpkgs-unstable;
    nixpkgs-unstable.url = github:NixOS/nixpkgs/nixpkgs-unstable;
    # for mac setup using nix-darwin
    darwin.url = github:lnl7/nix-darwin/master;
    darwin.inputs.nixpkgs.follows = "nixpkgs-unstable";
    flake-utils.url = github:numtide/flake-utils;
  };

  outputs = { self, darwin, nixpkgs, flake-utils, ... }@inputs:
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
                minimal =
                  darwinSystem {
                    inherit system;
                    modules = attrValues self.darwinModules ++ [
                      # nix-darwin configuration
                      ./default.nix
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
