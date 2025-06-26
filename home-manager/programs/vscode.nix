{ config, pkgs, ... }:
let
  trace-enable = builtins.trace "checking nixpkgs config.allowUnfree: ${builtins.toJSON pkgs.config.allowUnfree}" (true);
in
with pkgs;
{
  # https://github.com/nix-community/home-manager/blob/master/modules/programs/vscode.nix
  # https://github.com/nix-community/nix-vscode-extensions
  programs.vscode = {
    enable = trace-enable;
    profiles.default = {
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
        "terminal.external.osxExec" = "/opt/homebrew/bin/ghostty";
        "terminal.explorerKind" = "external";
        "workbench.sideBar.location" = "right";
        "editor.inlineSuggest.suppressSuggestions" = true;
        "amazonQ.telemetry" = false;
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
          ms-vscode.extension-test-runner
          ms-vscode.remote-server
          ms-vscode-remote.remote-containers
          ms-vscode-remote.remote-ssh
          ms-vscode-remote.remote-ssh-edit
          ms-vscode-remote.remote-wsl
          ms-vscode-remote.vscode-remote-extensionpack
          ms-python.python
          ms-toolsai.jupyter
          eamodio.gitlens
          redhat.vscode-yaml
          tailscale.vscode-tailscale
          unifiedjs.vscode-mdx
          graphql.vscode-graphql
          graphql.vscode-graphql-syntax
          leanprover.lean4
          dnicolson.binary-plist
          garmin.monkey-c
          amazonwebservices.amazon-q-vscode
          sourcegraph.cody-ai
          # jetbrains.jetbrains-ai-assistant
          cucumberopen.cucumber-official
        ]
        # ++ (lib.optionals stdenv.isDarwin [ withfig.fig ])
      ;
    };
    mutableExtensionsDir = true;
  };
}
