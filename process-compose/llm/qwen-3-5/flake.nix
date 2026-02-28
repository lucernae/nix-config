{
  description = "Flake to run Ollama with process-compose and include DeepSeek R1 7B models with optional GPU support on Linux";

  inputs = {
    # Required inputs
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    process-compose-flake.url = "github:Platonic-Systems/process-compose-flake";
    flake-parts.url = "github:hercules-ci/flake-parts";
    systems.url = "github:nix-systems/default";
    hf-nix.url = "github:huggingface/hf-nix";
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import inputs.systems;

      imports = [
        inputs.process-compose-flake.flakeModule
      ];

      perSystem = { self', system, ... }:
        let
          # Apply hf-nix overlay to pkgs
          pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [ inputs.hf-nix.overlays.default ];
          };
        in
        # Ollama configuration (disabled - using llama.cpp instead)
          # let
          #   # Override ollama to use v0.17.4
          #   ollamaBase = pkgs.ollama.overrideAttrs (oldAttrs: {
          #     version = "0.17.4";
          #     src = pkgs.fetchFromGitHub {
          #       owner = "ollama";
          #       repo = "ollama";
          #       rev = "v0.17.4";
          #       hash = "sha256-9yJ8Jbgrgiz/Pr6Se398DLkk1U2Lf5DDUi+tpEIjAaI=";
          #     };
          #
          #     # Use proxyVendor to properly fetch dependencies with C files
          #     proxyVendor = true;
          #     vendorHash = "sha256-dGMx8ltvlqhdzAfvvE5EliTcTNxGnzwcyLQTP71fGwA=";
          #
          #     # Add tree-sitter dependency for v0.17.4
          #     buildInputs = (oldAttrs.buildInputs or [ ]) ++ [ pkgs.tree-sitter ];
          #
          #     # Update postPatch to work with v0.17.4 structure
          #     postPatch = ''
          #       substituteInPlace version/version.go \
          #         --replace-fail 0.0.0 '0.17.4'
          #
          #       # Remove files/directories that exist (ignore errors for missing ones)
          #       rm -rf app || true
          #       rm -f ml/backend/ggml/ggml_test.go || true
          #       rm -f ml/nn/pooling/pooling_test.go || true
          #     '';
          #   });
          #
          #   # Conditional GPU support for Linux
          #   ollamaWithGpu =
          #     if (lib.strings.hasPrefix "x86_64-linux" system || lib.strings.hasPrefix "aarch64-linux" system) then
          #       ollamaBase.overrideAttrs
          #         (oldAttrs: {
          #           buildInputs = with pkgs; (oldAttrs.buildInputs or [ ]) ++ [
          #             #                  cuda # CUDA support
          #             #                  cudnn # NVIDIA cuDNN library
          #             #                  nvidia-packages.nvidia_drivers # NVIDIA drivers if required
          #             #                              rocm-opencl-icd #gaming?
          #
          #             #                              rocmPackages.clr.icd #following for GPU AI acceleration
          #             rocmPackages.rocm-smi
          #             rocmPackages.clr
          #             rocmPackages.hipblas
          #             rocmPackages.rocblas
          #             rocmPackages.rocsolver
          #             rocmPackages.rocm-comgr
          #             rocmPackages.rocm-runtime
          #             rocmPackages.rocsparse
          #             #
          #             #                              rocm-opencl-runtime #gaming?
          #             #                              libva #some hardware acceleration for stuff like OBS
          #             #                              vaapiVdpau
          #             #                              libvdpau-va-gl
          #           ];
          #           passthru.gpuSupport = true;
          #         })
          #     else
          #       ollamaBase;
          # in
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
                  # Ollama service definition (disabled - using llama.cpp instead)
                  # ollama = {
                  #   command = ''
                  #     ${ollamaWithGpu}/bin/ollama serve
                  #   '';
                  #   readiness_probe.http_get = {
                  #     host = "localhost";
                  #     inherit port;
                  #   };
                  # };

                  # deepseek-run = {
                  #   command = ''
                  #     ${ollamaWithGpu}/bin/ollama run deepseek-r1:7b
                  #   '';
                  #   depends_on."ollama".condition = "process_healthy";
                  # };

                  # qwen-3-5b = {
                  #   command = ''
                  #     ${ollamaWithGpu}/bin/ollama run qwen3.5:27b
                  #   '';
                  #   depends_on."ollama".condition = "process_healthy";
                  # };

                  # Qwen3.5-27B using llama.cpp with GGUF model (better for 16GB Mac)
                  qwen-llama = {
                    command = ''
                      # Download model if not present
                      MODEL_DIR="''${LLAMA_CACHE:-$HOME/.cache/qwen3.5-27b-gguf}"
                      MODEL_FILE="$MODEL_DIR/Qwen3.5-27B-Q4_K_M.gguf"

                      if [ ! -f "$MODEL_FILE" ]; then
                        echo "Downloading Qwen3.5-27B Q4_K_M model..."
                        mkdir -p "$MODEL_DIR"
                      fi

                      echo "Starting Qwen3.5-27B server with llama.cpp..."
                      ${pkgs.llama-cpp}/bin/llama-server \
                        --model "$MODEL_FILE" \
                        --port 8001 \
                        --alias "unsloth/qwen35" \
                        --ctx-size 20000 \
                        --temp 0.7 \
                        --top-p 0.8 \
                        --top-k 20 \
                        --min-p 0.00 \
                        -ngl 99
                    '';
                  };
                };
              };
            };

          packages.default = self'.packages.llm;

          # Development shell including dependencies for working on AI stack
          devShells.default = pkgs.mkShell {
            buildInputs = [
              # ollamaWithGpu
              pkgs.process-compose
              pkgs.llama-cpp
              pkgs.python3Packages.hf-transfer
              # pkgs.python3Packages.huggingface-hub
            ];
            #          ++ lib.optional (lib.strings.hasPrefix "x86_64-linux" system || lib.strings.hasPrefix "aarch64-linux" system) pkgs.cuda;

            shellHook = ''
              export LLAMA_CACHE="$HOME/.cache/qwen3.5-27b-gguf"
              echo "Qwen3.5-27B environment ready!"
              echo "Run: process-compose up"
              echo "Model cache: $LLAMA_CACHE"
            '';
          };
        };
    };
}
