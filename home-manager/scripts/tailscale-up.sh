#!/bin/sh
# This script starts the tailscaled daemon and initiates authentication.

# Ensure tailscaled is not already running
if ! pgrep -x "tailscaled" > /dev/null; then
  echo "Starting tailscaled..."
  # Use sudo as tailscaled typically requires root privileges
  sudo mkdir -p /var/tailscaled
  sudo tailscaled --tun=userspace-networking --statedir /var/tailscaled
else
  echo "tailscaled is already running."
  # If already running, check status
  sudo tailscale status
fi