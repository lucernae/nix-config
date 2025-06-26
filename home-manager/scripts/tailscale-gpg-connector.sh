# /workspaces/nix-config/home-manager/scripts/zsh/gpg-connector.sh
#!/bin/sh

# This script is managed by home-manager and runs in the Codespace.
# It connects to the local laptop's GPG agent via Tailscale and socat.

# Your local laptop's Tailscale machine name
LAPTOP_TAILSCALE_NAME="recalune-air"
# The port socat is listening on your laptop
SOCAT_PORT="23456"
# The path where the GPG agent socket will be created in the Codespace
CODESPACE_GPG_SOCKET="$HOME/.gnupg/S.gpg-agent"

# Ensure the .gnupg directory exists
mkdir -p "$HOME/.gnupg"

# Check if socat is already running for this connection
# We look for a process that has the specific socat command line arguments
if pgrep -f "socat UNIX-LISTEN:${CODESPACE_GPG_SOCKET}.*TCP:${LAPTOP_TAILSCALE_NAME}:${SOCAT_PORT}" > /dev/null; then
  # echo "GPG agent connector already running."
  exit 0
fi

# Clean up any stale socket file
rm -f "${CODESPACE_GPG_SOCKET}"

# Start socat in the background
# fork: forks a process for each connection
# unlink-early: removes the socket file before starting to listen, useful for cleanup
# discon-client: disconnects client if connection to server is lost
# reuseaddr: allows immediate reuse of the address
# bind: binds to a specific address (optional, but good practice)
# echo "Starting GPG agent connector..."
socat \
  UNIX-LISTEN:"${CODESPACE_GPG_SOCKET}",fork,unlink-early,reuseaddr \
  TCP:"${LAPTOP_TAILSCALE_NAME}":"${SOCAT_PORT}" &

# Set GPG_TTY for pinentry to work correctly
export GPG_TTY=$(tty)

# Inform the user (optional, can be removed for cleaner output)
# echo "GPG agent connector started. GPG_TTY set."