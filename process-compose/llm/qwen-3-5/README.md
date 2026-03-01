# Qwen 3.5 LLM Flake

This flake provides a simple way to run Qwen 3.5 models using either **Ollama** or **llama.cpp** as the backend, with optional GPU support (CUDA on Linux).

## Quick Start

Run directly from GitHub without cloning:

```bash
nix run "github:lucernae/nix-config?dir=process-compose/llm/qwen-3-5"
```

Or clone and run locally:

```bash
nix run .#llm
```

## Backend Options

### llama.cpp (Default)

Uses llama.cpp server with automatic model downloading from Hugging Face.

```bash
nix run .#llm
```

### Ollama

Uses Ollama with pre-downloaded GGUF models. Requires manual model download.

```bash
USE_OLLAMA=1 nix run .#llm
```

## Configuration

### Model Customization

Override default model settings via environment variables:

```bash
MODEL_REPO=owner/repo \
MODEL_NAME=model-name \
QUANTIZATION=Q4_K_M \
nix run .#llm
```

### Default Settings

- **Model Repository**: `unsloth/Qwen3.5-35B-A3B-GGUF`
- **Model Name**: `Qwen3.5-35B-A3B`
- **Quantization**: `UD-IQ2_XXS`
- **MMProj Model**: `mmproj-F16.gguf` (for vision capabilities)
- **API Port**: `11434`

### Cache Directory

- **Linux**: `/var/llm-models`
- **macOS**: `$HOME/.cache/llm-models/qwen-gguf`
- **Custom**: Set `LLAMA_CACHE` environment variable

## GPU Support

On Linux, CUDA support is enabled by default with compute capabilities: 6.1, 7.0, 7.5, 8.0, 8.6. Adjust `cudaCapabilities` in flake.nix for your GPU.

## Development Shell

Enter the dev shell for manual operations:

```bash
nix develop
```

This provides access to:
- `process-compose`
- `llama-cpp` or `ollama` (depending on USE_OLLAMA)
- Hugging Face CLI tools (`hf`)
- `pi-coding-agent` (auto-installed)

## Manual Model Download

If using Ollama or want to pre-download models:

```bash
nix develop
hf download unsloth/Qwen3.5-35B-A3B-GGUF \
  --local-dir $MODEL_DIR \
  --include "*UD-IQ2_XXS*"
```
