{ config, pkgs, ... }:
{
    programs.git = {
      enable = true;
      userName = "Rizky Maulana Nugraha";
      userEmail = "lana.pcfre@gmail.com";
      signing = {
        key = "69AC1656";
        signByDefault = true;
      };
      extraConfig = {
        core.editor = "code";
        safe.directory = [
          "/workspaces"
          "/workspaces/nix-config"
        ];
      };
    };
}