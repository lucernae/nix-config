{ config, pkgs, ... }:
{
  home.packages = [
    pkgs.unstable.gemini-cli
  ];
}
