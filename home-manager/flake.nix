{
  description = "Lucernae's home-manager flake";

  inputs = {
    # Specify the source of Home Manager and Nixpkgs.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Flake utils
    flake-utils.url = "github:numtide/flake-utils";
    # devenv
    devenv.url = "github:cachix/devenv/latest";
    # VS Code Nix Community
    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
  };

  outputs = { self, nixpkgs, home-manager, flake-utils, devenv, nix-vscode-extensions, ... }:
    let
      inherit (flake-utils.lib) system eachSystem;
    in
    eachSystem [
      system.x86_64-linux
      system.x86_64-darwin
      system.aarch64-darwin
      system.aarch64-linux
    ]
      (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
            overlays = [
              (final: prev: {
                nix-vscode-extensions = nix-vscode-extensions.extensions.${system};
              })
            ];
          };
        in
        rec {
          formatter = nixpkgs.legacyPackages.${system}.nixpkgs-fmt;
          packages.homeConfigurations.recalune = home-manager.lib.homeManagerConfiguration {
            inherit pkgs;

            # Specify your home configuration modules here, for example,
            # the path to your home.nix.
            modules = [
              ./recalune.nix
            ];

            extraSpecialArgs = {
              inherit (devenv.packages.${system}) devenv;
            };
          };
          packages.homeConfigurations.vscode = home-manager.lib.homeManagerConfiguration {
            inherit pkgs;

            # Specify your home configuration modules here, for example,
            # the path to your home.nix.
            modules = [
              ./vscode.nix
            ];

            extraSpecialArgs = {
              inherit (devenv.packages.${system}) devenv;
            };
          };
        }
      );
}
