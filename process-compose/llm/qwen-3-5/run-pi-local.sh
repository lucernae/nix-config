#!/usr/bin/env bash
# Run pi-coding-agent with local llama-server backend

set -e

# Set API endpoint to local llama-server (OpenAI-compatible)
export OPENAI_BASE_URL="http://localhost:${MODEL_API_PORT:-11434}"
export ANTHROPIC_BASE_URL="$OPENAI_BASE_URL"  # For compatibility with claude code

echo "Starting pi-coding-agent with local llama-server backend..."
echo "Base URL: $OPENAI_BASE_URL"
echo ""
echo "You also need to add the model definitions in ~/.pi/agent/models.json to use the model with pi-coding-agent:"
echo '{
  "providers": {
    "ollama": {
      "api": "openai-completions",
      "apiKey": "ollama",
      "models": [
        { "id": "unsloth/qwen35" }
      ]
    }
  }
}'
echo ""

pi --model unsloth/qwen35 "$@"
