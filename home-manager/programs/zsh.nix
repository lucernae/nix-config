{ config, pkgs, lib, ... }:
{
  programs.zsh = {
    enable = true;
    dotDir = ".nix-zsh";
    completionInit = ''
      autoload -Uz compinit && compinit -i
    '';
    initContent = lib.mkMerge [
      (lib.mkBefore ''
        # Amazon Q pre block. Keep at the top of this file.
        [[ -f "''${HOME}/Library/Application Support/amazon-q/shell/zshrc.pre.zsh" ]] && builtin source "''${HOME}/Library/Application Support/amazon-q/shell/zshrc.pre.zsh"
      '')
      (lib.mkOrder 550 ''
        ZSH_DISABLE_COMPFIX=true
      '')
      ''
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

        # Set PATH for Rancher Desktop
        export PATH="$HOME/.rd/bin:$PATH"

        # GPG
        export GPG_TTY=$(tty)
        gpgconf --launch gpg-agent

        # Sourcing custom scripts
        source ~/.scripts/zsh/*.sh

        # Run GPG connector script for Codespaces
        if [[ -n "$CODESPACES" ]]; then
          ~/.scripts/zsh/gpg-connector.sh
        fi

        # Amazon Q post block. Keep at the bottom of this file.
        [[ -f "''${HOME}/Library/Application Support/amazon-q/shell/zshrc.post.zsh" ]] && builtin source "''${HOME}/Library/Application Support/amazon-q/shell/zshrc.post.zsh"
      ''
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
      hmsf = "NIXPKGS_ALLOW_UNFREE=1 home-manager switch --impure --flake ~/.config/nix-config/home-manager#$(whoami)";
      hmb = "home-manager build";
      # nixos-rebuild
      nrs = "sudo nixos-rebuild switch";
      nrsf = "sudo NIXPKGS_ALLOW_UNFREE=1 nixos-rebuild switch --impure --flake ~/.config/nix-config";
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
        drsf = "NIXPKGS_ALLOW_UNFREE=1 darwin-rebuild switch --impure --flake ~/.config/nix-config";
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
