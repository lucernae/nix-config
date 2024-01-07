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
    # Pinentry-Box
    pinentry-box.url = "github:lucernae/pinentry-box?dir=pinentry-box";
  };

  outputs =
    { self
    , nixpkgs
    , home-manager
    , flake-utils
    , devenv
    , nix-vscode-extensions
    , pinentry-box
    , ...
    }:
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
                pinentry-box = pinentry-box.packages.${system}.pinentry_box;
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
          packages.homeConfigurations.vmware = home-manager.lib.homeManagerConfiguration {
            inherit pkgs;

            # Specify your home configuration modules here, for example,
            # the path to your home.nix.
            modules = [
              ./vmware.nix
            ];

            extraSpecialArgs = {
              inherit (devenv.packages.${system}) devenv;
            };
          };
        }
      );
}
