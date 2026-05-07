{ config, pkgs, lib, ... }:
{
  home.packages = [
    pkgs.unstable.claude-code
  ];

  home.activation.claude-statusline = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p ${config.home.homeDirectory}/.claude
    $DRY_RUN_CMD ln -sf ${config.home.homeDirectory}/.config/nix-config/home-manager/scripts/claude-statusline.sh \
      ${config.home.homeDirectory}/.claude/statusline.sh
    $DRY_RUN_CMD ln -sf ${config.home.homeDirectory}/.config/nix-config/home-manager/scripts/statusline.yaml \
      ${config.home.homeDirectory}/.claude/statusline.yaml
  '';
}
