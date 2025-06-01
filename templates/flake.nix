{
  description = "Flake templates for various project types";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = import nixpkgs { inherit system; };
          # Function to create a template entry
          mkTemplate = name: description:
            {
              name = name;
              value = {
                path = ./${name};
                description = description;
              };
            };

          # Template definitions with descriptions
          templateDefs = [
            { name = "devshell"; description = "A simple development shell template"; }
            # python-uv template will be available after processing
            # { name = "python-uv"; description = "A Python development shell with uv package manager"; }
            # python-mcp template will be available after processing
            # { name = "python-mcp"; description = "A Model Context Protocol (MCP) project with fastmcp"; }
          ];


          # Function to create a template app
          mkTemplateApp = name:
            let
              script = pkgs.writeShellScript name ''
                exec ${./metatemplates/process-templates.sh} --source ${./metatemplates}/${name} --context ${./metatemplates}/${name}/context.template.nix "$@"
              '';
            in
            {
              name = name;
              value = {
                type = "app";
                program = "${script}";
              };
            };

          # List of template names
          templateNames = [ "devshell" "python-uv" "python-mcp" ];

          # Generate apps for each template
          templateApps = builtins.listToAttrs (map mkTemplateApp templateNames);
        in
        {
          # Add the process-templates app and template apps
          apps = {
            process-templates = {
              type = "app";
              program = ./metatemplates/process-templates.sh;
            };
            default = self.apps.${system}.process-templates;
          } // templateApps;
          metatemplates = { };

          # Generate templates for each definition
          templates = builtins.listToAttrs (map (def: mkTemplate def.name def.description) templateDefs);
        });
}
