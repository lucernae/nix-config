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
  };

  outputs = {self, nixpkgs, home-manager, flake-utils, ...}:
    let
        inherit (flake-utils.lib) system eachSystem;
    in
    eachSystem [
        system.x86_64-linux
        system.x86_64-darwin
        system.aarch64-darwin
    ] (
        system: 
            let
                pkgs = nixpkgs.legacyPackages.${system};
            in
            rec {
            packages.homeConfigurations.recalune = home-manager.lib.homeManagerConfiguration {
                inherit pkgs;

                # Specify your home configuration modules here, for example,
                # the path to your home.nix.
                modules = [
                ./recalune.nix
                ];
            };
            packages.homeConfigurations.vscode = home-manager.lib.homeManagerConfiguration {
                inherit pkgs;

                # Specify your home configuration modules here, for example,
                # the path to your home.nix.
                modules = [
                ./vscode.nix
                ];
            };
        }
    );
}
