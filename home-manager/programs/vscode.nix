{ config, pkgs, ... }:
with pkgs;
{
    # https://github.com/nix-community/home-manager/blob/master/modules/programs/vscode.nix
    programs.vscode = {
        enable = true;
        enableUpdateCheck = true;
        extensions = with vscode-extensions; [
            bbenoist.nix
            github.codespaces
            golang.go
            ms-azuretools.vscode-docker
            # ms-vscode-remote.remote-containers
            ms-vscode-remote.remote-ssh
            # ms-vscode-remote.remote-ssh-edit
            # ms-vscode-remote.remote-wsl
            # ms-vscode-remote.vscode-remote-extensionpack
            # ms-vscode-remote.remote-explorer
            # ms-vscode.makefile-tools
        ] 
        # ++ (lib.optionals stdenv.isDarwin [ withfig.fig ])
        ;
        mutableExtensionsDir = true;
    };
}