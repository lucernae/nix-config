{ config, pkgs, home-manager, ... }:
{

  services.skhd = {
    enable = true;
    skhdConfig = ''
      # directional ijkl
      alt - k : yabai -m window --focus south
      alt - i : yabai -m window --focus north
      alt - j : yabai -m window --focus west
      alt - l : yabai -m window --focus east

      # directional awsd
      alt - s : yabai -m window --focus south
      alt - w : yabai -m window --focus north
      alt - a : yabai -m window --focus west
      alt - d : yabai -m window --focus east

      # display focus change
      alt - f : yabai -m display --focus west
      alt - g : yabai -m display --focus east
      # for alternating between display
      alt - h : yabai -m display --focus recent
      # immediate display targeting
      ctrl + alt - 1 : yabai -m display --focus 1
      ctrl + alt - 2 : yabai -m display --focus 2

      # rotate layout clockwise
      shift + alt - r : yabai -m space --rotate 270

      # flip along y-axis
      shift + alt - t : yabai -m space --mirror y-axis

      # flip along x-axis
      shift + alt - e : yabai -m space --mirror x-axis

      # toggle window float
      shift + alt - q : yabai -m window --toggle float --grid 4:4:1:1:2:2

      # maximize window
      shift + alt - c : yabai -m window --toggle zoom-fullscreen

      # balancing space
      shift + alt - h : yabai -m space --balance

      # swap windows
      shift + alt - k : yabai -m window --swap south
      shift + alt - i : yabai -m window --swap north
      shift + alt - j : yabai -m window --swap west
      shift + alt - l : yabai -m window --swap east

      # transfer windows
      ctrl + alt - k : yabai -m window --warp south
      ctrl + alt - i : yabai -m window --warp north
      ctrl + alt - j : yabai -m window --warp west
      ctrl + alt - l : yabai -m window --warp east

      # move window over spaces
      shift + alt - v : yabai -m window --space prev
      shift + alt - b : yabai -m window --space next

      # move window to space
      shift + alt - 1 : yabai -m window --space 1
      shift + alt - 2 : yabai -m window --space 2
      shift + alt - 3 : yabai -m window --space 3
      shift + alt - 4 : yabai -m window --space 4
      shift + alt - 5 : yabai -m window --space 5
      shift + alt - 6 : yabai -m window --space 6
      shift + alt - 7 : yabai -m window --space 7
      shift + alt - 8 : yabai -m window --space 8
      shift + alt - 9 : yabai -m window --space 9

      # start stop yabai
      ctrl + alt - q : launchctl stop org.nixos.yabai
      ctrl + alt - s : launchctl start org.nixos.yabai

      # apply skhd config
      ctrl + alt - r : launchctl stop org.nixos.skhd; launchctl start org.nixos.skhd;
    '';
  };
}
