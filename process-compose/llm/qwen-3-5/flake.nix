{
  description = "Flake to run Qwen 3.5 models using either Ollama or Llama.cpp with process-compose, with optional GPU support";

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

      perSystem = { self', lib, system, ... }:
        let
          # Apply hf-nix overlay to pkgs
          pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [ inputs.hf-nix.overlays.default ];
            config = {
              # You can tweak this config according to your GPU
              allowUnfree = true;
              cudaSupport = true;  # Enable CUDA support for packages like llama-cpp
              # My GTX 1080 support (compute capability 6.1)
              cudaCapabilities = [ "6.1" "7.0" "7.5" "8.0" "8.6" ];
              cudaForwardCompat = false;
            };
          };
        in
        let
          # Override ollama to use v0.17.4
          ollamaBase = pkgs.ollama.overrideAttrs (oldAttrs: {
            version = "0.17.4";
            src = pkgs.fetchFromGitHub {
              owner = "ollama";
              repo = "ollama";
              rev = "v0.17.4";
              hash = "sha256-9yJ8Jbgrgiz/Pr6Se398DLkk1U2Lf5DDUi+tpEIjAaI=";
            };

            # Use proxyVendor to properly fetch dependencies with C files
            proxyVendor = true;
            vendorHash = "sha256-Lc1Ktdqtv2VhJQssk8K1UOimeEjVNvDWePE9WkamCos=";

            # Add tree-sitter dependency for v0.17.4
            buildInputs = (oldAttrs.buildInputs or [ ]) ++ [ pkgs.tree-sitter ];

            # Update postPatch to work with v0.17.4 structure
            postPatch = ''
              substituteInPlace version/version.go \
                --replace-fail 0.0.0 '0.17.4'

              # Remove files/directories that exist (ignore errors for missing ones)
              rm -rf app || true
              rm -f ml/backend/ggml/ggml_test.go || true
              rm -f ml/nn/pooling/pooling_test.go || true
            '';
          });

          # Ollama with GPU support
          # The base ollama package (v0.17.4) has built-in GPU support (CUDA/ROCm)
          # and will automatically detect and use available GPUs
          ollamaWithGpu = ollamaBase;

          # Model configuration parameters
          # These can be overridden via environment variables
          modelRepo = builtins.getEnv "MODEL_REPO";
          modelName = builtins.getEnv "MODEL_NAME";
          quantization = builtins.getEnv "QUANTIZATION";
          mmprojmodel = builtins.getEnv "MM_PROJ_MODEL";

          # Defaults if not set
          defaultModelRepo = "unsloth/Qwen3.5-35B-A3B-GGUF";
          defaultModelName = "Qwen3.5-35B-A3B";
          defaultQuantization = "UD-IQ2_XXS";
          defaultMmProjModel = "mmproj-F16.gguf";

          # Use environment variable or default
          finalModelRepo = if modelRepo != "" then modelRepo else defaultModelRepo;
          finalModelName = if modelName != "" then modelName else defaultModelName;
          finalQuantization = if quantization != "" then quantization else defaultQuantization;
          finalMmProjModel = if mmprojmodel != "" then mmprojmodel else defaultMmProjModel;

          # Construct model file name
          modelFileName = "${finalModelName}-${finalQuantization}.gguf";

          # Toggle between ollama and llama.cpp
          # Set USE_OLLAMA=1 to use Ollama, otherwise use llama.cpp
          useOllama = builtins.getEnv "USE_OLLAMA" != "";

          # default model API port
          port = 11434;
        in
        rec {


          # Setup process-compose for running Qwen 3.5 with either Ollama or llama.cpp
          process-compose."llm" =
            {
              cli = {
                # Environment configurations
              };

              settings = {
                environment = {
                  # Optional environment variables for Ollama or other integrations
                  OLLAMA_HOST = "localhost:${builtins.toString port}";
                  # Set Ollama models directory
                  OLLAMA_MODELS = "/var/llm-models/.ollama/models";
                };

                processes = {
                  # Ollama service definition
                  ollama = pkgs.lib.mkIf useOllama {
                    command = ''
                      ${ollamaWithGpu}/bin/ollama serve
                    '';
                    readiness_probe.http_get = {
                      host = "localhost";
                      inherit port;
                    };
                  };

                  # Qwen using Ollama with pre-downloaded GGUF model
                  qwen-ollama = pkgs.lib.mkIf useOllama {
                    command = ''
                      MODEL_DIR="''${LLAMA_CACHE:-${if pkgs.stdenv.isLinux then "/var/llm-models" else "$HOME/.cache/qwen-gguf"}}"
                      MODEL_FILE="$MODEL_DIR/${modelFileName}"

                      echo "Checking for GGUF model at $MODEL_FILE..."

                      if [ ! -f "$MODEL_FILE" ]; then
                        echo "Error: Model file not found at $MODEL_FILE"
                        echo "Please download the model first or set LLAMA_CACHE to the correct directory"
                        exit 1
                      fi

                      # Create Modelfile for Ollama
                      MODELFILE=$(mktemp)
                      cat > "$MODELFILE" <<EOF
                      FROM $MODEL_FILE
                      PARAMETER temperature 0.7
                      PARAMETER top_p 0.8
                      PARAMETER top_k 20
                      PARAMETER num_ctx 20000
                      EOF

                      echo "Creating Ollama model from GGUF file..."
                      ${ollamaWithGpu}/bin/ollama create qwen3.5 -f "$MODELFILE"

                      echo "Running ${finalModelName} with Ollama..."
                      ${ollamaWithGpu}/bin/ollama run qwen3.5
                    '';
                    depends_on."ollama".condition = "process_healthy";
                  };

                  # Qwen using llama.cpp with GGUF model (better for 24GB Mac)
                  qwen-llama = pkgs.lib.mkIf (!useOllama) {
                    command = ''
                      # Download model if not present
                      MODEL_DIR="''${LLAMA_CACHE:-${if pkgs.stdenv.isLinux then "/var/llm-models" else "$HOME/.cache/llm-models/qwen-gguf"}}"
                      MODEL_FILE="$MODEL_DIR/${modelFileName}"
                      MM_PROJ_MODEL="''${MM_PROJ_MODEL:-${finalMmProjModel}}"
                      MM_PROJ_MODEL_FILE="$MODEL_DIR/$MM_PROJ_MODEL"

                      if [ ! -f "$MODEL_FILE" ]; then
                        echo "Downloading ${finalModelName} ${finalQuantization} model..."
                        mkdir -p "$MODEL_DIR"
                        hf download ${finalModelRepo} \
                          --local-dir $MODEL_DIR \
                          --include "*${finalQuantization}*"
                      fi

                      if [ ! -f "$MM_PROJ_MODEL_FILE" ]; then
                        echo "Downloading MMProj model to $MM_PROJ_MODEL_FILE ..."
                        hf download ${finalModelRepo} \
                          --local-dir $MODEL_DIR \
                          --include "$MM_PROJ_MODEL"
                      fi

                      echo "Starting ${finalModelName} server with llama.cpp..."
                      ${pkgs.llama-cpp}/bin/llama-server \
                        --model "$MODEL_FILE" \
                        --mmproj "$MM_PROJ_MODEL_FILE" \
                        --port ${builtins.toString port} \
                        --alias "unsloth/qwen35" \
                        --ctx-size 20000 \
                        --temp 0.7 \
                        --top-p 0.8 \
                        --top-k 20 \
                        --min-p 0.00

                        sleep infinity
                    '';
                  };
                };
              };
            };

          packages.default = self'.packages.llm;

          # Development shell including dependencies for working on AI stack
          devShells.default = pkgs.mkShell {
            buildInputs = [
              pkgs.process-compose
              pkgs.llama-cpp
              pkgs.python3Packages.hf-transfer
              pkgs.python3Packages.huggingface-hub
              pkgs.nodejs
            ] ++ lib.optionals useOllama [
              ollamaWithGpu  # Only included when USE_OLLAMA=1
            ];
            #          ++ lib.optional (lib.strings.hasPrefix "x86_64-linux" system || lib.strings.hasPrefix "aarch64-linux" system) pkgs.cuda;

            shellHook = ''
              # Set up local npm directory for global packages
              export NPM_CONFIG_PREFIX="''${NPM_CONFIG_PREFIX:-$PWD/.npm-global}"
              export PATH="$NPM_CONFIG_PREFIX/bin:$PATH"

              # Install pi-coding-agent if not already installed
              if ! command -v pi &> /dev/null; then
                echo "Installing pi-coding-agent..."
                npm install -g @mariozechner/pi-coding-agent
              fi

              export LLAMA_CACHE="''${LLAMA_CACHE:-${if pkgs.stdenv.isLinux then "/var/llm-models" else "$HOME/.cache/llm-models/qwen-gguf"}}"
              export MODEL_DIR="''${LLAMA_CACHE:-${if pkgs.stdenv.isLinux then "/var/llm-models" else "$HOME/.cache/llm-models/qwen-gguf"}}"
              export MODEL_REPO="''${MODEL_REPO:-${finalModelRepo}}"
              export MODEL_NAME="''${MODEL_NAME:-${finalModelName}}"
              export QUANTIZATION="''${QUANTIZATION:-${finalQuantization}}"
              export MODEL_FILE="$MODEL_DIR/${modelFileName}"
              export MM_PROJ_MODEL="''${MM_PROJ_MODEL:-${defaultMmProjModel}}"
              export MM_PROJ_MODEL_FILE="$MODEL_DIR/$MM_PROJ_MODEL"
              export MODEL_API_PORT="${builtins.toString port}"
              echo "Qwen environment ready!"
              echo ""
              echo "Model configuration:"
              echo "  Repository: $MODEL_REPO"
              echo "  Model: $MODEL_NAME"
              echo "  Quantization: $QUANTIZATION"
              echo "  MMProj Model: $MM_PROJ_MODEL"
              echo "  File: $MODEL_FILE"
              echo "  MMProj File: $MM_PROJ_MODEL_FILE"
              echo ""
              echo "To download model, run:"
              echo "hf download $MODEL_REPO --local-dir $MODEL_DIR --include \"*$QUANTIZATION*\""
              echo ""
              echo "To download MMProj model, run:"
              echo "hf download $MODEL_REPO --local-dir $MODEL_DIR --include \"$MM_PROJ_MODEL\""
              echo ""
              echo "Available backends:"
              echo "  - llama.cpp (default): nix run .#llm"
              echo "  - Ollama: USE_OLLAMA=1 nix run .#llm"
              echo ""
              echo "Customize model:"
              echo "  MODEL_REPO=owner/repo MODEL_NAME=name QUANTIZATION=quant nix run .#llm"
              echo ""
              echo "Or build and run separately:"
              echo "  nix build .#llm && ./result/bin/llm-pc"
              echo ""
              echo "Model cache: $LLAMA_CACHE"
            '';
          };
        };
    };
}
