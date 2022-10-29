{ config, pkgs, ... }:
{
  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "recalune";
  home.homeDirectory = "/Users/recalune";

  home.packages = with pkgs; [
    htop
    zsh
    oh-my-zsh
    git
    vim
  ];

  programs = {
    direnv = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };
    git = {
      enable = true;
      userName = "Rizky Maulana Nugraha";
      userEmail = "lana.pcfre@gmail.com";
      signing = {
        key = "69AC1656";
        signByDefault = true;
      };
      extraConfig = {
        core.editor = "vim";
        safe.directory = [
          "/usr/local/Homebrew"
          "/usr/local/Homebrew/Library/Taps/homebrew/homebrew-bundle"
          "/usr/local/Homebrew/Library/Taps/homebrew/homebrew-core"
          "/usr/local/Homebrew/Library/Taps/homebrew/homebrew-cask"
        ];
      };
    };
    gpg = {
      enable = true;
      package = pkgs.gnupg23;
      settings = {
        use-agent = true;
        # pinentry-program = "/usr/local/bin/pinentry-mac";
      };
    };
    zsh = {
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
        theme = "robbyrussell";
      };
      shellAliases = {
        hm = "home-manager";
        hms = "home-manager switch";
        hmb = "home-manager build";
        drs = "darwin-rebuild switch";
        drb = "darwin-rebuild build";
      };
    };
  };

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "22.05";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
