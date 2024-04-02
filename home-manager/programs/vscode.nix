{ config, pkgs, ... }:
with pkgs;
{
  # https://github.com/nix-community/home-manager/blob/master/modules/programs/vscode.nix
  # https://github.com/nix-community/nix-vscode-extensions
  programs.vscode = {
    enable = true;
    enableUpdateCheck = true;
    userSettings = {
      "editor.stickyScroll.enabled" = true;
      "git.enableCommitSigning" = true;
      "editor.fontFamily" = "'FiraCode Nerd Font', 'DroidSans Nerd Font', Menlo, Monaco, 'Courier New', monospace";
      "nix.enableLanguageServer" = true;
      "nix.serverPath" = "nixd";
      "terminal.integrated.automationProfile.linux" = { };
      "terminal.integrated.defaultProfile.osx" = "zsh";
      "terminal.integrated.defaultProfile.linux" = "zsh";
      "terminal.integrated.enableMultiLinePasteWarning" = false;
      "terminal.integrated.env.linux" = { };
      "terminal.integrated.env.osx" = { };
      "workbench.sideBar.location" = "right";
    };
    extensions =
      # with (nix-vscode-extensions.forVSCodeVersion config.programs.vscode.package.version).vscode-marketplace;
      with nix-vscode-extensions.vscode-marketplace;
      [
        bbenoist.nix
        jnoortheen.nix-ide
        github.codespaces
        github.vscode-github-actions
        golang.go
        ms-azuretools.vscode-docker
        ms-kubernetes-tools.vscode-kubernetes-tools
        # ms-vscode.makefile-tools
        ms-vscode.remote-server
        ms-vscode-remote.remote-containers
        ms-vscode-remote.remote-ssh
        ms-vscode-remote.remote-ssh-edit
        ms-vscode-remote.remote-wsl
        ms-vscode-remote.vscode-remote-extensionpack
        eamodio.gitlens
        redhat.vscode-yaml
        tailscale.vscode-tailscale
        unifiedjs.vscode-mdx
        graphql.vscode-graphql
        graphql.vscode-graphql-syntax
        leanprover.lean4
      ]
      # ++ (lib.optionals stdenv.isDarwin [ withfig.fig ])
    ;
    mutableExtensionsDir = false;
  };
}
