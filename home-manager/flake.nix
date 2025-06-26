{
  description = "Lucernae's home-manager flake";

  inputs = {
    # Specify the source of Home Manager and Nixpkgs.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
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
          nixpkgsConfig = {
            config = {
              allowUnfree = true;
              allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) [
                "vscode-extension-github-codespaces"
              ];
            };
          };
          pkgs = import nixpkgs {
            inherit system;
            inherit (nixpkgsConfig) config;
            overlays = [
              (final: prev: {
                nix-vscode-extensions = nix-vscode-extensions.extensions.${system};
                pinentry-box = pinentry-box.packages.${system}.pinentry_box;
                pinentry-box-cli = pinentry-box.packages.${system}.pinentry_box_cli;
                gemini-cli = final.callPackage ./packages/gemini-cli { };
              })
            ];
          };
          homeConfigurations = {
            recalune = home-manager.lib.homeManagerConfiguration {
              inherit pkgs;
              modules = [
                { nixpkgs = nixpkgsConfig; }
                ./recalune.nix
              ];
              extraSpecialArgs = {
                inherit (devenv.packages.${system}) devenv;
              };
            };
            vscode = home-manager.lib.homeManagerConfiguration {
              inherit pkgs;
              modules = [
                { nixpkgs = nixpkgsConfig; }
                ./vscode.nix
              ];
              extraSpecialArgs = {
                inherit (devenv.packages.${system}) devenv;
              };
            };
            vmware = home-manager.lib.homeManagerConfiguration {
              inherit pkgs;
              modules = [
                { nixpkgs = nixpkgsConfig; }
                ./vmware.nix
              ];
              extraSpecialArgs = {
                inherit (devenv.packages.${system}) devenv;
              };
            };
          };
        in
        rec {
          formatter = nixpkgs.legacyPackages.${system}.nixpkgs-fmt;

          # The homeConfigurations are now packages.
          packages.homeConfigurations = homeConfigurations;
          packages.gemini-cli =
            let
              gemini-cli = pkgs.callPackage ./packages/gemini-cli { };
            in
            gemini-cli;

          # Add the devShell for the recalune configuration.
          devShells.default =
            let
              # Get the current PATH from the host environment.
              currentPath = builtins.getEnv "PATH";
              # Split the PATH into a list of individual directory paths.
              currentPathList = pkgs.lib.strings.splitString ":" currentPath;

              # Filter out the old home-manager generation path to avoid duplicates and conflicts.
              # This identifies the path by its characteristic name.
              filteredPathList = pkgs.lib.lists.filter
                (p: !(pkgs.lib.strings.hasInfix "-home-manager-generation" p))
                currentPathList;

              # Get the current username to select the correct home configuration.
              username = builtins.getEnv "USER";
              # Default to 'recalune' if the user is not in the map.
              activeConfigName = if builtins.hasAttr username homeConfigurations then username else "recalune";
              activeHomeConfig = homeConfigurations.${activeConfigName};

              # Construct the new, clean PATH.
              # 1. Prepend the new home-manager profile's bin directory.
              # 2. Add the filtered list of existing paths.
              # 3. Ensure the final list has no duplicates.
              # 4. Join the list back into a PATH string.
              devPath = pkgs.lib.strings.concatStringsSep ":" (pkgs.lib.lists.unique ([
                "${activeHomeConfig.activationPackage}/bin"
              ] ++ filteredPathList));
            in
            pkgs.mkShell {
              name = "home-manager-shell";

              inputsFrom = [
                activeHomeConfig.activationPackage
              ];

              buildInputs = [
                home-manager.packages.${system}.home-manager
                pkgs.zsh
              ];
              env = {
                NIXPKGS_ALLOW_UNFREE = 1;
              };

              # The shellHook now simply exports the PATH we constructed in the 'let' block.
              shellHook = ''
                export PATH="${devPath}"
                echo "Entered home-manager development shell for user: ${username}"
                echo "Using configuration for '${activeConfigName}'."
                echo "The 'home-manager' command and all packages from the '${activeConfigName}' configuration are available."
                echo "You can now run 'hmsf' or 'home-manager switch --flake .#${activeConfigName}'"

                # If we are in an interactive shell, switch to zsh
                if [[ -n "$PS1" && -z "$INSIDE_NIX_SHELL_ZSH" ]]; then
                  export INSIDE_NIX_SHELL_ZSH=1
                  exec ${pkgs.zsh}/bin/zsh
                fi
              '';
            };
        }
      );
}