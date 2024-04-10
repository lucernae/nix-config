{ config, pkgs, home-manager, ... }:
{
  system.defaults = {
    loginwindow = {
      GuestEnabled = false;
      LoginwindowText = "Be the change you wish to see in the world";

    };
    finder = {
      AppleShowAllFiles = true;
      ShowStatusBar = true;
      ShowPathbar = true;
      AppleShowAllExtensions = true;
      QuitMenuItem = true;
      # needed by yabai
      CreateDesktop = true;
    };
    smb = {
      NetBIOSName = "recalune";
      ServerDescription = "Recalune's Macbook Air";
    };
    SoftwareUpdate = {
      AutomaticallyInstallMacOSUpdates = false;
    };
    # to retrieve current value of NSGlobalDomain
    # defaults read NSGlobalDomain
    NSGlobalDomain = {
      AppleShowAllFiles = true;
      AppleEnableSwipeNavigateWithScrolls = false;
      AppleInterfaceStyleSwitchesAutomatically = true;
      AppleShowAllExtensions = true;
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = false;
      NSAutomaticSpellingCorrectionEnabled = false;
      "com.apple.keyboard.fnState" = true;
      "com.apple.springing.delay" = 0.5;
      "com.apple.springing.enabled" = true;
      "com.apple.trackpad.scaling" = 0.6875;
    };
    menuExtraClock = {
      IsAnalog = false;
      Show24Hour = true;
      ShowAMPM = false;
      ShowDayOfMonth = true;
      ShowDayOfWeek = true;
      ShowDate = 0;
      ShowSeconds = true;
    };
    dock = {
      autohide = false;
      wvous-tl-corner = 2;
      wvous-bl-corner = 11;
      wvous-br-corner = 14;
      wvous-tr-corner = 3;
    };
    #    spaces.spans-displays = false;
    trackpad = {
      Clicking = false;
      Dragging = false;
      TrackpadRightClick = true;
      TrackpadThreeFingerDrag = false;
      ActuationStrength = 1;
      FirstClickThreshold = 1;
      SecondClickThreshold = 1;
    };


  };
}
