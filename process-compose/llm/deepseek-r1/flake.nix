{
  description = "Flake to run Ollama with process-compose and include DeepSeek R1 7B models";

  inputs = {
    # Required inputs
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    process-compose-flake.url = "github:Platonic-Systems/process-compose-flake";
    flake-parts.url = "github:hercules-ci/flake-parts";
    systems.url = "github:nix-systems/default";
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import inputs.systems;

      imports = [
        inputs.process-compose-flake.flakeModule
      ];

      perSystem = { self', pkgs, lib, ... }: rec {
        # Setup process-compose for Ollama service with DeepSeek model
        process-compose."llm" =
          let
            # default ollama port
            port = 11434;
          in {
            cli = {
              # Environment configurations
            };

            settings = {
              environment = {
                # Optional environment variables for Ollama or other integrations
                OLLAMA_HOST = "localhost:${builtins.toString port}";
              };

              processes = {
                # Ollama service definition
                ollama = {
                  command = ''
                    ${pkgs.ollama}/bin/ollama serve
                  '';
                  readiness_probe.http_get = {
                    host = "localhost";
                    inherit port;
                  };
                };

                deepseek-run = {
                  command = ''
                    ${pkgs.ollama}/bin/ollama run deepseek-r1:7b
                  '';
                  depends_on."ollama".condition = "process_healthy";
                };
              };
            };
          };
        packages.default = self'.packages.llm;

        # Development shell including dependencies for working on AI stack
        devShells.default = pkgs.mkShell {
          buildInputs = [
            pkgs.ollama
            pkgs.process-compose
          ];
        };
      };
    };
}