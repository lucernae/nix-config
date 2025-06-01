{
  description = "A Model Context Protocol (MCP) project with fastmcp";

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

        python = pkgs."python311";
      in
      {
        apps.default = {
          type = "app";
          program = toString (pkgs.writeShellScript "run-mcp" ''
            ${pkgs.uv}/bin/uvx --from ${./.} mcp-server
          '');
        };

        devShells.default = pkgs.devshell.mkShell {
          name = "python-mcp";
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
              help = "Install dependencies from requirements.txt and pyproject.toml using uv";
              command = "uv pip install -e .";
            }
            {
              name = "run-mcp";
              help = "Run the MCP server using uv run";
              command = "uv run mcp-server";
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
