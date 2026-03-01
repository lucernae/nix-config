#!/usr/bin/env bash
# Run Claude Code CLI with local llama-server backend

set -e

# Set API endpoint to local llama-server
export ANTHROPIC_BASE_URL="http://localhost:${MODEL_API_PORT:-8001}"

echo "Starting Claude Code with local llama-server backend..."
echo "Base URL: $ANTHROPIC_BASE_URL"
echo ""

# Run claude code with any arguments passed to this script
claude --model unsloth/qwen35 --dangerously-skip-permissions "$@"
