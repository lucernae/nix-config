# SSH Agent via GPG Agent
# When programs.gnupg.agent.enableSSHSupport is true in NixOS configuration,
# gpg-agent provides SSH agent functionality and integrates with KWallet for password prompts

function sshagent_init {
    # Use gpg-agent's SSH socket instead of traditional ssh-agent
    # This provides KWallet integration for SSH key password prompts

    # Get the SSH socket path from gpg-agent
    GPG_SSH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"

    if [ -z "$GPG_SSH_SOCK" ]; then
        echo "Error: Could not find gpg-agent SSH socket"
        echo "Make sure gpg-agent is running and SSH support is enabled"
        return 1
    fi

    # Set SSH_AUTH_SOCK to use gpg-agent
    export SSH_AUTH_SOCK="$GPG_SSH_SOCK"

    # Ensure gpg-agent is running
    if ! gpg-connect-agent /bye > /dev/null 2>&1; then
        echo "Starting gpg-agent..."
        gpgconf --launch gpg-agent
    fi

    # Verify the socket is working
    if [ -S "$SSH_AUTH_SOCK" ]; then
        echo "Using gpg-agent SSH socket: $SSH_AUTH_SOCK"

        # Show currently loaded SSH keys
        ssh-add -l

        if [ $? = 2 ]; then
            echo "gpg-agent is running but no SSH keys are loaded"
            echo "Add your SSH keys with: ssh-add ~/.ssh/id_rsa"
        fi
    else
        echo "Error: SSH socket is not available at $SSH_AUTH_SOCK"
        return 1
    fi
}

# Legacy functions for backward compatibility (now use gpg-agent)
function sshagent_findsockets {
    # No longer needed with gpg-agent, but kept for compatibility
    echo "$(gpgconf --list-dirs agent-ssh-socket)"
}

function sshagent_testsocket {
    # Test the gpg-agent SSH socket
    GPG_SSH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"

    if [ -S "$GPG_SSH_SOCK" ]; then
        export SSH_AUTH_SOCK="$GPG_SSH_SOCK"
        ssh-add -l > /dev/null 2>&1
        case $? in
            0|1)
                echo "Found gpg-agent SSH socket: $GPG_SSH_SOCK"
                return 0
                ;;
            2)
                echo "gpg-agent SSH socket is dead or not responding"
                return 4
                ;;
        esac
    else
        echo "gpg-agent SSH socket not found"
        return 3
    fi
}
