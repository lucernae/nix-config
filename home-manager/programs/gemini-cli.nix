{ config, pkgs, ... }:
{
  home.packages = [
    # from the overlay for now
    pkgs.gemini-cli
  ];
}
