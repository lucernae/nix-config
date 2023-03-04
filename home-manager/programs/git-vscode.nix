{ config, pkgs, ... }:
{
  programs.git = {
    enable = true;
    userName = "Rizky Maulana Nugraha";
    userEmail = "lana.pcfre@gmail.com";
    extraConfig = {
      core.editor = "code";
    };
  };
}
