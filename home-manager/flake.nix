{
  description = "Lucernae's home-manager flake";

  inputs = {
    # Specify the source of Home Manager and Nixpkgs.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
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
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    # Vicinae
    vicinae.url = "github:vicinaehq/vicinae";
    vicinae-extensions = {
      url = "github:vicinaehq/extensions";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Google Antigravity
    antigravity-nix = {
      url = "github:jacopone/antigravity-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self
    , nixpkgs
    , home-manager
    , flake-utils
    , devenv
    , nix-vscode-extensions
    , pinentry-box
    , nixpkgs-unstable
    , vicinae
    , vicinae-extensions
    , antigravity-nix
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
            };
          };
          pkgs = import nixpkgs {
            inherit system;
            inherit (nixpkgsConfig) config;
            overlays = [
              (final: prev:
                let
                  isDarwin = builtins.elem system [
                    "x86_64-darwin"
                    "aarch64-darwin"
                  ];
                in
                {
                  unstable = import nixpkgs-unstable {
                    system = prev.stdenv.hostPlatform.system;
                    inherit (nixpkgsConfig) config;
                  };
                  lima = final.unstable.lima;
                  nix-vscode-extensions = nix-vscode-extensions.extensions.${system};
                  pinentry-box = pinentry-box.packages.${system}.pinentry_box;
                  pinentry-box-cli = pinentry-box.packages.${system}.pinentry_box_cli;
                # gemini-cli = final.callPackage ./packages/gemini-cli { };
                } // (prev.lib.optionalAttrs isDarwin {
                  # Override inetutils to use 2.6 instead of 2.7 (2.7 fails on Darwin)
                  inetutils = prev.inetutils.overrideAttrs (oldAttrs: {
                    version = "2.6";
                    src = prev.fetchurl {
                      url = "mirror://gnu/inetutils/inetutils-2.6.tar.xz";
                      sha256 = "sha256-aL7b/q9z99hr4qfZm8+9QJPYKfUncIk5Ga4XTAsjV8o=";
                    };
                    # Remove CVE-2026-24061_2.patch which is for 2.7
                    patches = builtins.filter (p:
                      !(prev.lib.hasInfix "CVE-2026-24061" (toString p))
                    ) (oldAttrs.patches or []);
                  });
                })
              )
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
            lucernae = home-manager.lib.homeManagerConfiguration {
              inherit pkgs;
              modules = [
                { nixpkgs = nixpkgsConfig; }
                vicinae.homeManagerModules.default
                ./lucernae.nix
              ];
              extraSpecialArgs = {
                inherit (devenv.packages.${system}) devenv;
                inherit vicinae-extensions;
              };
            };
          };
        in
        rec {
          formatter = nixpkgs.legacyPackages.${system}.nixpkgs-fmt;

          # The homeConfigurations are now packages.
          packages.homeConfigurations = homeConfigurations;
          # packages.gemini-cli =
          #   let
          #     gemini-cli = pkgs.callPackage ./packages/gemini-cli { };
          #   in
          #   gemini-cli;

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
