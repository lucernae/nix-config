{ config, pkgs, home-manager, ... }:
{
  services.yabai = {
    enable = true;
    config = {
      window_placement = "second_child";
      layout = "bsp";
      top_padding = 8;
      bottom_padding = 8;
      left_padding = 8;
      right_padding = 8;
      window_gap = 8;
      mouse_follows_focus = "on";
      mouse_modifier = "alt";
      mouse_action1 = "move";
      mouse_action2 = "resize";
      mouse_drop_action = "swap";
    };
    extraConfig = ''
      yabai -m rule --add app="^System Settings" manage=off
      yabai -m rule --add app="^Raycast" manage=off
      yabai -m signal --add app='^Ghostty$' event=window_created action='yabai -m space --layout bsp'
      yabai -m signal --add app='^Ghostty$' event=window_destroyed action='yabai -m space --layout bsp'
    '';
  };
}
