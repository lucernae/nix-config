{ config, pkgs, lib, ... }:
{
  programs.zsh = {
    enable = true;
    dotDir = "${config.home.homeDirectory}/.nix-zsh";
    completionInit = ''
      autoload -Uz compinit && compinit -i
    '';
    initContent = lib.mkMerge [
      (lib.mkOrder 550 ''
        ZSH_DISABLE_COMPFIX=true
      '')

      # Common initialization (both Linux and macOS)
      ''
        # Set PATH for Rancher Desktop
        export PATH="$HOME/.rd/bin:$PATH"

        # NPM global packages
        export NPM_CONFIG_PREFIX="$HOME/.npm-global"
        export PATH="$HOME/.npm-global/bin:$PATH"

        # Sourcing custom scripts
        source ~/.scripts/zsh/*.sh


      ''

      # macOS/Darwin specific initialization
      (lib.optionalString pkgs.stdenv.isDarwin ''
        # Set PATH, MANPATH, etc., for Homebrew.
        # Doesn't need it now since we are using nix-homebrew
        # Intel Mac uses this one
        if [[ "$(uname)" == "Darwin" && "$(arch)" == "i386" ]]; then
          eval "$(/usr/local/bin/brew shellenv)"
        fi
        # ARM Mac uses this one
        if [[ "$(uname)" == "Darwin" && "$(arch)" == "arm64" ]]; then
          eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
      '')

      # Linux specific initialization
      (lib.optionalString pkgs.stdenv.isLinux ''
        # DBus session - required for KWallet integration
        export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"

        # SSH askpass - use ksshaskpass for KWallet integration with SSH keys
        export SSH_ASKPASS="/run/current-system/sw/bin/ksshaskpass"
        export SSH_ASKPASS_REQUIRE=prefer

        # GPG and SSH Agent via gpg-agent
        # Note: GPG_TTY is NOT set to allow graphical pinentry (KWallet) to work
        # If you need terminal-based pinentry, uncomment the line below:
        # export GPG_TTY=$(tty)
        gpgconf --launch gpg-agent

        # Set SSH_AUTH_SOCK to use gpg-agent (enables KWallet integration)
        export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
      '')
    ];
    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
        "kubectl"
        "docker"
        "docker-compose"
      ];
      theme = "bira";
    };
    prezto = {
      enable = false;
      pmodules = [
        "autosuggestions"
        "completion"
        "directory"
        "editor"
        "git"
        "kubectl"
        "docker"
        "docker-compose"
        "terminal"
      ];
    };
    shellAliases = {
      # home-manager
      hm = "home-manager";
      hms = "home-manager switch";
      hmsf = "NIXPKGS_ALLOW_UNFREE=1 NIXPKGS_ALLOW_INSECURE=1 home-manager switch --impure --flake ~/.config/nix-config/home-manager#$(whoami)";
      hmb = "home-manager build";
      # nixos-rebuild
      nrs = "sudo nixos-rebuild switch";
      nrsf = "sudo NIXPKGS_ALLOW_UNFREE=1 NIXPKGS_ALLOW_INSECURE=1 nixos-rebuild switch --impure --flake ~/.config/nix-config";
      nrb = "nixos-rebuild build";
      # sshagent
      sagent = "sshagent_init";
      # git
      gca = "git commit -a -m";
      gcammend = "git commit -a --amend --no-edit";
      gpo = "git pull origin --rebase";
      gpu = "git push origin -u";
      gsc = "git switch main -c";
      gco = "git checkout";
      gs = "git status";
      gl = "git log";
      gls = "git log --show-signature";
      grs = "git reset --soft";
      grh = "git reset --hard";
    } // (
      pkgs.lib.optionalAttrs pkgs.stdenv.isDarwin {
        # macos specific
        # darwin-rebuild
        drs = "darwin-rebuild switch";
        drsf = "sudo NIXPKGS_ALLOW_UNFREE=1 darwin-rebuild switch --impure --flake ~/.config/nix-config";
        drb = "darwin-rebuild build";

        # launchctl
        lcr = "launchctl_restart";
        reloadyabai = ''
          launchctl unload -w ~/Library/LaunchAgents/org.nixos.yabai.plist
          launchctl unload -w ~/Library/LaunchAgents/org.nixos.skhd.plist
          launchctl load -w ~/Library/LaunchAgents/org.nixos.skhd.plist
          launchctl load -w ~/Library/LaunchAgents/org.nixos.yabai.plist
        '';
        # macos screensharing enable
        msse = "sudo defaults write /var/db/launchd.db/com.apple.launchd/overrides.plist com.apple.screensharing -dict Disabled -bool false && sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.screensharing.plist";
        mssd = "sudo defaults write /var/db/launchd.db/com.apple.launchd/overrides.plist com.apple.screensharing -dict Disabled -bool true && sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.screensharing.plist";
        tailscale = "/Applications/Tailscale.app/Contents/MacOS/Tailscale";
      }
    );
  };
}
