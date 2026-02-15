{ config, pkgs, ... }:
let
  trace-enable = builtins.trace "checking nixpkgs config.allowUnfree: ${builtins.toJSON pkgs.config.allowUnfree}" (true);

  # Helper function to patch extension binaries to use Nix node
  patchExtensionForNix = ext: ext.overrideAttrs (oldAttrs: {
    buildPhase = (oldAttrs.buildPhase or "") + ''
      # Find and patch dynamically linked executables to use Nix node
      find . -type f -executable 2>/dev/null | while read -r binary; do
        # Check if it's a dynamically linked ELF binary
        if ${pkgs.file}/bin/file "$binary" 2>/dev/null | grep -q "ELF.*dynamically linked"; then
          chmod +w "$binary" 2>/dev/null || true
          # Patch the binary to use Nix interpreter
          ${pkgs.patchelf}/bin/patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" "$binary" 2>/dev/null || true
        fi
      done
    '';
  });

  # Custom patched extensions
  extensions-override = {
    # Claude Code with Nix-installed claude binary
    claude-code = pkgs.nix-vscode-extensions.vscode-marketplace.anthropic.claude-code.overrideAttrs (oldAttrs: {
      buildPhase = (oldAttrs.buildPhase or "") + ''
        # Replace the bundled native binary with a symlink to the Nix-installed claude
        if [ -f "resources/native-binary/claude" ]; then
          chmod +w resources/native-binary/claude
          rm -f resources/native-binary/claude
          ln -sf "${pkgs.unstable.claude-code}/bin/claude" resources/native-binary/claude
        fi
      '';
    });

    # MS extensions patched for NixOS
    ms-python = patchExtensionForNix pkgs.nix-vscode-extensions.vscode-marketplace.ms-python.python;
    ms-vscode-remote-containers = patchExtensionForNix pkgs.nix-vscode-extensions.vscode-marketplace.ms-vscode-remote.remote-containers;
    ms-vscode-remote-ssh = patchExtensionForNix pkgs.nix-vscode-extensions.vscode-marketplace.ms-vscode-remote.remote-ssh;
  };
in
with pkgs;
{
  # https://github.com/nix-community/home-manager/blob/master/modules/programs/vscode/default.nix
  # https://github.com/nix-community/nix-vscode-extensions
  programs.vscode = {
    enable = trace-enable;
    package = pkgs.unstable.vscode;
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
        "claudeCode.preferredLocation" = "panel";
      };
      extensions =
        (with nix-vscode-extensions.vscode-marketplace; [
          bbenoist.nix
          jnoortheen.nix-ide
          # github.codespaces  # Unfree license - use --impure flag if needed
          github.vscode-github-actions
          golang.go
          ms-azuretools.vscode-docker
          ms-kubernetes-tools.vscode-kubernetes-tools
          # ms-vscode.makefile-tools
          ms-vscode.extension-test-runner
          ms-vscode.remote-server
          ms-vscode-remote.remote-ssh-edit
          ms-vscode-remote.remote-wsl
          ms-vscode-remote.vscode-remote-extensionpack
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
          # jetbrains.jetbrains-ai-assistant
          cucumberopen.cucumber-official
        ]) ++ (with extensions-override; [
          # Patched extensions with NixOS fixes
          claude-code  # Uses Nix claude binary
          ms-python  # Patched for NixOS
          ms-vscode-remote-containers  # Patched for NixOS
          ms-vscode-remote-ssh  # Patched for NixOS
        ]);
    };
    mutableExtensionsDir = true;
  };
}
