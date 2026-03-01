#!/usr/bin/env bash
# Run llama-server with Qwen model (parameterizable)

set -e

# Model configuration (can be overridden via environment variables)
MODEL_REPO="${MODEL_REPO:-Qwen/Qwen3.5-35B-A3B}"
MODEL_NAME="${MODEL_NAME:-Qwen3.5-35B}"
QUANTIZATION="${QUANTIZATION:-UD-IQ2_XSS}"

# Set model directory and file
MODEL_DIR="${LLAMA_CACHE:-/var/llm-models}"
MODEL_FILE="$MODEL_DIR/${MODEL_NAME}-${QUANTIZATION}.gguf"

echo "Model Configuration:"
echo "  Repository: $MODEL_REPO"
echo "  Model: $MODEL_NAME"
echo "  Quantization: $QUANTIZATION"
echo "  File: $MODEL_FILE"
echo ""

# Check if model file exists
if [ ! -f "$MODEL_FILE" ]; then
  echo "Error: Model file not found at $MODEL_FILE"
  echo ""
  echo "To download the model, run:"
  echo "  hf download $MODEL_REPO --local-dir $MODEL_DIR --include \"*${QUANTIZATION}*\""
  echo ""
  echo "Or set LLAMA_CACHE to the correct directory"
  exit 1
fi

echo "Starting llama-server with model: $MODEL_FILE"


  # --batch-size 16384 \
  # --ubatch-size 512 \

# Run llama-server
llama-server \
  --model "$MODEL_FILE" \
  --mmproj "$MODEL_DIR/mmproj-F16.gguf" \
  --port 8001 \
  --alias "unsloth/qwen35" \
  --ctx-size 20000 \
  --temp 0.7 \
  --top-p 0.8 \
  --top-k 20 \
  --min-p 0.00
  # -ngl 30  # Optimized for GTX 1080 8GB: reduced batch sizes to fit more layers
