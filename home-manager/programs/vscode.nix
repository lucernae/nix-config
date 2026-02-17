{ config, pkgs, lib, ... }:
let
  trace-enable = builtins.trace "checking nixpkgs config.allowUnfree: ${builtins.toJSON pkgs.config.allowUnfree}" (true);

  # Default workspace settings that can be overridden
  defaultWorkspaceSettings = {
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
    "claudeCode.selectedModel" = "sonnet";
    "claudeCode.claudeProcessWrapper" = "/home/lucernae/.nix-profile/bin/claude";
  };

  # Allow users to override workspace settings via config
  workspaceSettings = lib.mkMerge [
    defaultWorkspaceSettings
    (lib.mkIf (config.programs.vscode.workspaceSettings or null != null) config.programs.vscode.workspaceSettings)
  ];

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
      # Don't manage userSettings to allow mutable settings
      # userSettings = workspaceSettings;
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
          claude-code # Uses Nix claude binary
          ms-python # Patched for NixOS
          ms-vscode-remote-containers # Patched for NixOS
          ms-vscode-remote-ssh # Patched for NixOS
        ]);
    };
    mutableExtensionsDir = true;
  };

  # Create a default settings template that users can reference
  home.file.".config/Code/User/settings.nix.example.json" = {
    text = builtins.toJSON defaultWorkspaceSettings;
  };

  # Activation script to merge default settings into user settings (only once)
  home.activation.vscodeDefaultSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    SETTINGS_FILE="$HOME/.config/Code/User/settings.json"
    DEFAULTS_FILE="$HOME/.config/Code/User/settings.nix.example.json"

    # If settings.json doesn't exist, create it with defaults
    if [ ! -f "$SETTINGS_FILE" ]; then
      $DRY_RUN_CMD mkdir -p "$(dirname "$SETTINGS_FILE")"
      $DRY_RUN_CMD cp "$DEFAULTS_FILE" "$SETTINGS_FILE"
      $DRY_RUN_CMD chmod +w "$SETTINGS_FILE"
      echo "Created VSCode settings.json with Nix defaults"
    else
      # Settings exist - user can manually merge from .nix.example.json if desired
      echo "VSCode settings.json exists - preserving user settings"
      echo "See ~/.config/Code/User/settings.nix.example.json for Nix-recommended defaults"
    fi
  '';
}
