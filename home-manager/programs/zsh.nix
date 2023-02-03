{ config, pkgs, ... }:
{
    programs.zsh = {
      enable = true;
      completionInit = ''
        autoload -Uz compinit && compinit -i
      '';
      initExtraBeforeCompInit = ''
        ZSH_DISABLE_COMPFIX=true
      '';
      initExtraFirst = ''
        # Fig pre block. Keep at the top of this file.
        [[ -f "$HOME/.fig/shell/zshrc.pre.zsh" ]] && builtin source "$HOME/.fig/shell/zshrc.pre.zsh"
      '';
      initExtra = ''
        # Set PATH, MANPATH, etc., for Homebrew.
        eval "$(/opt/homebrew/bin/brew shellenv)" || eval "$(/usr/local/bin/brew shellenv)"

        # Set PATH for Rancher Desktop
        export PATH="$HOME/.rd/bin:$PATH"

        # GPG
        export GPG_TTY=$(tty)
        gpgconf --launch gpg-agent

        # Fig post block. Keep at the bottom of this file.
        [[ -f "$HOME/.fig/shell/zshrc.post.zsh" ]] && builtin source "$HOME/.fig/shell/zshrc.post.zsh"
      '';
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
        hm = "home-manager";
        hms = "home-manager switch";
        hmsf = "home-manager switch --flake ~/.config/nix-config/home-manager#$(whoami)";
        hmb = "home-manager build";
        drs = "darwin-rebuild switch";
        drsf = "darwin-rebuild switch --flake ~/.config/nix-config";
        drb = "darwin-rebuild build";
      };
    };
}
