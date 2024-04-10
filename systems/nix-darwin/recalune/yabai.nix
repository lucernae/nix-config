{ config, pkgs, home-manager, ... }:
{
  services.yabai = {
    enable = true;
    config = {
      window_placement = "second_child";
      layout = "bsp";
      top_padding = 16;
      bottom_padding = 16;
      left_padding = 16;
      right_padding = 16;
      window_gap = 16;
      mouse_follows_focus = "on";
      mouse_modifier = "alt";
      mouse_action1 = "move";
      mouse_action2 = "resize";
      mouse_drop_action = "swap";
    };
    extraConfig = ''
      yabai -m rule --add app="^System Settings" manage=off
      yabai -m rule --add app="^Raycast" manage=off
    '';
  };
}
