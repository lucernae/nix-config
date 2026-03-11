{
  description = "Flake to run Ollama with process-compose and include DeepSeek R1 7B models with optional GPU support on Linux";

  inputs = {
    # Required inputs
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
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

      perSystem = { self', pkgs, lib, system, ... }:
        let
          # Conditional GPU support for Linux
          ollamaWithGpu =
            if (lib.strings.hasPrefix "x86_64-linux" system || lib.strings.hasPrefix "aarch64-linux" system) then
              pkgs.ollama.overrideAttrs
                (oldAttrs: {
                  buildInputs = with pkgs; (oldAttrs.buildInputs or [ ]) ++ [
                    #                  cuda # CUDA support
                    #                  cudnn # NVIDIA cuDNN library
                    #                  nvidia-packages.nvidia_drivers # NVIDIA drivers if required
                    #                              rocm-opencl-icd #gaming?

                    #                              rocmPackages.clr.icd #following for GPU AI acceleration
                    rocmPackages.rocm-smi
                    rocmPackages.clr
                    rocmPackages.hipblas
                    rocmPackages.rocblas
                    rocmPackages.rocsolver
                    rocmPackages.rocm-comgr
                    rocmPackages.rocm-runtime
                    rocmPackages.rocsparse
                    #
                    #                              rocm-opencl-runtime #gaming?
                    #                              libva #some hardware acceleration for stuff like OBS
                    #                              vaapiVdpau
                    #                              libvdpau-va-gl
                  ];
                  passthru.gpuSupport = true;
                })
            else
              pkgs.ollama;
        in
        rec {


          # Setup process-compose for Ollama service with DeepSeek model
          process-compose."llm" =
            let
              # default ollama port
              port = 11434;
            in
            {
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
                      ${ollamaWithGpu}/bin/ollama serve
                    '';
                    readiness_probe.http_get = {
                      host = "localhost";
                      inherit port;
                    };
                  };

                  deepseek-run = {
                    command = ''
                      ${ollamaWithGpu}/bin/ollama run deepseek-r1:7b
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
              ollamaWithGpu
              pkgs.process-compose
            ];
            #          ++ lib.optional (lib.strings.hasPrefix "x86_64-linux" system || lib.strings.hasPrefix "aarch64-linux" system) pkgs.cuda;
          };
        };
    };
}
