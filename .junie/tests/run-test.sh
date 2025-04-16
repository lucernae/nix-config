#!/usr/bin/env bash

# Exit on error
set -e

# Change to the directory containing this script
cd "$(dirname "$0")"

echo "Running home-manager configuration test..."
nix-build test-home-config.nix -A test

echo "Test completed successfully!"
