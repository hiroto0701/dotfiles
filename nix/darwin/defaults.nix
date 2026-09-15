{ ... }:
{
  system.defaults = {
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";
      KeyRepeat = 2;
      InitialKeyRepeat = 15;
      "com.apple.trackpad.scaling" = 3.0;
      "com.apple.swipescrolldirection" = true;
      "com.apple.trackpad.forceClick" = true;
      "com.apple.trackpad.enableSecondaryClick" = true;
      "com.apple.mouse.tapBehavior" = 1;
      NSAutomaticCapitalizationEnabled = true;
      NSAutomaticPeriodSubstitutionEnabled = true;
      NSTableViewDefaultSizeMode = 1;      # サイドバーアイコン: 小
      _HIHideMenuBar = false;
    };
    ".GlobalPreferences"."com.apple.mouse.scaling" = 2.5;
    hitoolbox.AppleFnUsageType = "Show Emoji & Symbols";   # 実値 2

    dock = {
      autohide = true;
      orientation = "left";
      tilesize = 16;
      magnification = true;
      largesize = 71;
      show-recents = false;
      mru-spaces = false;
      expose-group-apps = true;
      wvous-br-corner = 14;                # 右下ホットコーナー: クイックメモ
    };

    finder = {
      FXPreferredViewStyle = "clmv";       # カラム表示
      NewWindowTarget = "Recents";         # 実値 PfAF
      ShowPathbar = true;
      ShowExternalHardDrivesOnDesktop = true;
      ShowHardDrivesOnDesktop = false;
      ShowRemovableMediaOnDesktop = true;
    };

    trackpad = {
      Clicking = true;
      TrackpadRightClick = true;
      TrackpadThreeFingerDrag = true;
      # 3 本指ドラッグ有効時の連動値: 3 本指スワイプ/タップ = 0、4 本指 = 2
      TrackpadThreeFingerHorizSwipeGesture = 0;
      TrackpadThreeFingerVertSwipeGesture = 0;
      TrackpadThreeFingerTapGesture = 0;
      TrackpadFourFingerHorizSwipeGesture = 2;
      TrackpadFourFingerVertSwipeGesture = 2;
      TrackpadFourFingerPinchGesture = 2;
    };

    menuExtraClock = {
      ShowSeconds = true;
      ShowDayOfWeek = true;
      ShowAMPM = true;
      ShowDate = 0;
    };

    controlcenter = {
      BatteryShowPercentage = true;
      # false = メニューバーに出さない (実値 24)。nix-darwin の命名がこうなっている
      Bluetooth = false;
      Display = false;
    };

    WindowManager.EnableTiledWindowMargins = false;
    spaces.spans-displays = false;
    loginwindow.GuestEnabled = false;

    # 型付きオプションが無いものは domain/key を直接書く
    CustomUserPreferences = {
      NSGlobalDomain = {
        TISRomanSwitchState = 1;                       # Caps Lock で IME 切替
        "com.apple.scrollwheel.scaling" = 1.7;
        AppleMenuBarVisibleInFullscreen = true;
        "com.apple.sound.uiaudio.enabled" = 0;
        UIPreferredContentSizeCategoryName = "UICTContentSizeCategoryXS";
      };
      "com.apple.finder".ShowSidebar = false;
    };
  };
}
