# GPG Agent Forwarding with Tailscale and Socat

This document outlines a plan to securely connect a GPG agent running on a local machine to a remote environment like GitHub Codespaces using Tailscale and the `socat` utility.

This method avoids relying on SSH agent forwarding and instead creates a direct, secure bridge for the GPG socket over a private Tailscale network.

## High-Level Strategy

The strategy is to use `socat` to create a secure bridge for the GPG socket.
-   **On the local machine ("server"):** `socat` will expose the GPG Unix socket as a TCP service, but **only on the secure Tailscale network interface**.
-   **In the GitHub Codespace ("client"):** `socat` will connect to that TCP service and present it as a local GPG Unix socket for the `gpg` command to use.

**Visual Plan:**

```
[Your Local Laptop]                                      [GitHub Codespace]
-------------------                                      ------------------
1. gpg-agent (Unix socket)                               6. gpg command
      |                                                        |
      v                                                        v
2. socat (listens on TCP port, forwards to socket)       5. socat (creates a fake Unix socket)
      |                                                        ^
      +--------------------------------------------------------+
                   3. Tailscale Secure Network (TCP traffic)
```

---

## Phase 1: Prerequisites (Local and Codespace)

This plan requires the `socat` utility on both the local machine and the remote Codespace.

1.  **Install `socat` on your Local Laptop:**
    *   **macOS:** `brew install socat`
    *   **Linux (Debian/Ubuntu):** `sudo apt-get update && sudo apt-get install socat`
    *   **Linux (Fedora):** `sudo dnf install socat`

2.  **Install `socat` in the GitHub Codespace:**
    *   The Codespace is a Debian-based container. Install `socat` by running the following command in the Codespace terminal:
        ```bash
        sudo apt-get update && sudo apt-get install -y socat
        ```

---

## Phase 2: Configuration on Your Local Laptop (The "Server")

This step exposes your local GPG agent as a TCP service on your private Tailscale network.

1.  **Identify Your Local GPG Agent Socket:**
    *   Find the path to your active GPG agent socket.
    *   **Command:** `gpgconf --list-dirs agent-socket`

2.  **Identify Your Laptop's Tailscale IP:**
    *   Find the IP address assigned to your laptop by Tailscale. This ensures the GPG service is not exposed to any other network.
    *   **Command:** `tailscale ip -4`

3.  **Start the `socat` Bridge:**
    *   This command listens on a TCP port (e.g., `23456`) on your Tailscale IP and forwards all traffic to your GPG agent socket. This command must be left running in a terminal on your local machine.
    *   **Command:**
        ```bash
        # Replace with your actual Tailscale IP and GPG socket path from the commands above
        socat TCP-LISTEN:23456,bind=YOUR_LAPTOP_TAILSCALE_IP,fork UNIX-CONNECT:/path/to/your/agent.socket
        ```

---

## Phase 3: Configuration in the GitHub Codespace (The "Client")

This step connects to the service on your laptop and makes it available as a local socket in the Codespace.

1.  **Identify Your Laptop's Tailscale Name or IP:**
    *   You can use the Tailscale IP from the previous step, or your laptop's Tailscale machine name (e.g., `my-macbook`), which is more stable.

2.  **Start the `socat` Bridge in the Codespace:**
    *   This command creates a new GPG socket in the Codespace's `~/.gnupg/` directory and forwards all communication to your laptop over Tailscale.
    *   To make it persistent, you should add this command to your shell's startup file (e.g., `~/.zshrc` or `~/.bashrc`).
    *   **Command:**
        ```bash
        # Create the directory if it doesn't exist
        mkdir -p ~/.gnupg

        # Run the bridge in the background. Replace with your laptop's Tailscale name or IP.
        # The '&' runs the process in the background.
        socat UNIX-LISTEN:~/.gnupg/S.gpg-agent,fork,unlink-early TCP:your-laptop-tailscale-name:23456 &
        ```

3.  **Set the GPG_TTY Variable:**
    *   This is still required so that pinentry prompts can appear correctly on your local machine.
    *   **Action:** Add this line to your `~/.zshrc` or `~/.bashrc` in the Codespace:
        ```bash
        export GPG_TTY=$(tty)
        ```

---

## Phase 4: Verification

1.  **Reload the Codespace Shell:** Run `source ~/.zshrc` (or `source ~/.bashrc`) or simply restart the terminal.
2.  **Test the Connection:** Run a GPG command that requires private key access.
    *   **Test Command:** `echo "test data" | gpg -as -`
    *   **Expected Result:** A pinentry prompt should appear on your **local laptop**, not in the Codespace terminal. If this happens, the connection is working correctly.
