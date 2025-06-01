{
  description = "${context.description}";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-${context.nixpkgs-version}";
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
        
        python = pkgs."python${builtins.replaceStrings ["."] [""] context.python-version}";
      in
      {
        devShells.default = pkgs.devshell.mkShell {
          name = "${context.name}";
          packages = with pkgs; [
            # Python and uv
            python
            uv
            
            # Additional useful tools
            git
            curl
          ];
          
          commands = [
            {
              name = "setup-venv";
              help = "Create a virtual environment using uv";
              command = "uv venv";
            }
            {
              name = "install-deps";
              help = "Install dependencies from requirements.txt using uv";
              command = "uv pip install -r requirements.txt";
            }
          ];
          
          env = [
            {
              name = "PYTHONPATH";
              value = "$PRJ_ROOT";
            }
            {
              name = "PROJECT_ROOT";
              value = "$PRJ_ROOT";
            }
          ];
        };
      }
    );
}