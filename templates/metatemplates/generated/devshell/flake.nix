{
  description = "A simple development shell template";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    devshell.url = "github:numtide/devshell";
    devshell.inputs.nixpkgs.follows = "nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, devshell, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ devshell.overlays.default ];
        };
      in
      {
        devShells.default = pkgs.devshell.mkShell {
          name = "my-devshell";
          packages = with pkgs; [
            # Add your packages here
            git
            curl
            jq
          ];
          commands = [
            {
              name = "hello";
              help = "Print hello world";
              command = "echo 'Hello, World!'";
            }
            # Add more commands as needed
          ];
          env = [
            {
              name = "PROJECT_ROOT";
              value = "$PRJ_ROOT";
            }
            # Add more environment variables as needed
          ];
        };
      }
    );
}
