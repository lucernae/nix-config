{ config, pkgs, ... }:
{
  programs.git = {
    enable = true;
    signing = {
      key = "69AC1656";
      signByDefault = true;
    };
    settings = {
      user.name = "Rizky Maulana Nugraha";
      user.email = "lana.pcfre@gmail.com";
      core.editor = "code";
      safe.directory = [
        "/workspaces"
        "/workspaces/nix-config"
      ];
    };
  };
}
