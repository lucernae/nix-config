#!/usr/bin/env bash

# special setup script since we want to use the codespace/devcontainer immediately for /home/vscode
mkdir -p /home/vscode/.config
ln -sf /workspaces/nix-config /home/vscode/.config/nix-config
