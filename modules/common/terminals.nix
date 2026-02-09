{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    # Terminal options
    xterm            # Default terminal (lightweight)
    rxvt-unicode     # Alternative terminal (customizable)
    wezterm          # Modern terminal (GPU-accelerated)

    # Terminal wrapper scripts for easy switching
    (writeShellScriptBin "term-xterm" ''
      exec ${xterm}/bin/xterm \
        -fa "JetBrains Mono" -fs 8 \
        -bg "#1d1f21" -fg "#c5c8c6" \
        -cr "#c5c8c6" \
        -e ${zsh}/bin/zsh "$@"
    '')
    
    (writeShellScriptBin "term-urxvt" ''
      ${xrdb}/bin/xrdb -merge ~/.Xresources 2>/dev/null || true
      exec ${rxvt-unicode}/bin/urxvt "$@"
    '')
    
    (writeShellScriptBin "term-wezterm" ''
      exec ${wezterm}/bin/wezterm "$@"
    '')
    
    # Default terminal (configurable)
    (writeShellScriptBin "terminal" ''
      # Default to xterm, but allow override with TERMINAL env var
      case "''${TERMINAL:-xterm}" in
        xterm)   exec term-xterm "$@" ;;
        urxvt)   exec term-urxvt "$@" ;;
        wezterm) exec term-wezterm "$@" ;;
        *)       exec term-xterm "$@" ;;
      esac
    '')
  ];

  # .Xresources for rxvt-unicode (based on your WSL config)
  home.file.".Xresources".text = ''
    ! XTerm color scheme (Tomorrow Night)
    *.foreground:   #c5c8c6
    *.background:   #1d1f21
    *.cursorColor:  #c5c8c6
    *.color0:       #282a2e
    *.color8:       #373b41
    *.color1:       #a54242
    *.color9:       #cc6666
    *.color2:       #8c9440
    *.color10:      #b5bd68
    *.color3:       #de935f
    *.color11:      #f0c674
    *.color4:       #F5F5DC
    *.color12:      #F5F5DC
    *.color5:       #85678f
    *.color13:      #b294bb
    *.color6:       #5e8d87
    *.color14:      #8abeb7
    *.color7:       #707880
    *.color15:      #c5c8c6

    ! URxvt color scheme (Tomorrow Night)
    URxvt.foreground:   #c5c8c6
    URxvt.background:   #1d1f21
    URxvt.cursorColor:  #c5c8c6

    ! black
    URxvt.color0:       #282a2e
    URxvt.color8:       #373b41

    ! red
    URxvt.color1:       #a54242
    URxvt.color9:       #cc6666

    ! green
    URxvt.color2:       #8c9440
    URxvt.color10:      #b5bd68

    ! yellow
    URxvt.color3:       #de935f
    URxvt.color11:      #f0c674

    ! blue
    URxvt.color4:       #F5F5DC
    URxvt.color12:      #F5F5DC

    ! magenta
    URxvt.color5:       #85678f
    URxvt.color13:      #b294bb

    ! cyan
    URxvt.color6:       #5e8d87
    URxvt.color14:      #8abeb7

    ! white
    URxvt.color7:       #707880
    URxvt.color15:      #c5c8c6

    !! URxvt Appearance
    URxvt.letterSpace: 0
    URxvt.lineSpace: 0
    URxvt.geometry: 92x24
    URxvt.internalBorder: 6
    URxvt.cursorBlink: true
    URxvt.cursorUnderline: false
    URxvt.saveline: 2048
    URxvt.scrollBar: false
    URxvt.scrollBar_right: false
    URxvt.urgentOnBell: true
    URxvt.depth: 24
    URxvt.iso14755: false
    URxvt.font: xft:JetBrains Mono:size=8
    URxvt.keysym.M-c: perl:clipboard:copy
    URxvt.keysym.M-v: perl:clipboard:paste
    URxvt.keysym.M-C-v: perl:clipboard:paste_escaped

    ! Copy/paste with Control+Insert and Shift+Insert
    URxvt.keysym.Control-Insert: eval:selection_to_clipboard
    URxvt.keysym.Shift-Insert: eval:paste_clipboard

    ! Ensure the clipboard extension is loaded
    URxvt.perl-ext-common: default,clipboard,url-select,keyboard-select
    URxvt.clipboard.autocopy: true
  '';

  # WezTerm configuration
  xdg.configFile."wezterm/wezterm.lua".text = ''
    local wezterm = require 'wezterm'
    local config = {}

    -- Font configuration
    config.font = wezterm.font('JetBrains Mono')
    config.font_size = 8.0

    -- Color scheme
    config.color_scheme = 'Tomorrow Night'

    -- Window configuration
    config.initial_rows = 24
    config.initial_cols = 80
    
    -- Disable ligatures for compatibility
    config.harfbuzz_features = { 'calt=0', 'clig=0', 'liga=0' }
    
    -- Key bindings
    config.keys = {
      -- Copy/paste
      { key = 'c', mods = 'ALT', action = wezterm.action.CopyTo 'Clipboard' },
      { key = 'v', mods = 'ALT', action = wezterm.action.PasteFrom 'Clipboard' },
    }

    return config
  '';

  # Environment variables for terminal selection
  home.sessionVariables = {
    # Default terminal (can be overridden)
    TERMINAL = "xterm";
  };
}
