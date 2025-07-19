{ config, pkgs, lib, inputs, overlays, globals, ... }: {
  # Unified Home Manager configuration for all machines
  # This replaces the duplicated crostini/tempest configurations
  
  home.username = globals.user;
  home.homeDirectory = "/home/${globals.user}";
  home.stateVersion = "24.05";
  
  # Import common modules
  imports = [
    # Common applications and configurations
    ../modules/common/applications/home-manager.nix
    ../modules/common/applications/age.nix
    ../modules/common/applications/i3.nix
  ];
  
  # Enable i3 window manager
  i3.enable = true;
  
  # Apply overlays and config for standalone use
  nixpkgs.overlays = overlays;
  nixpkgs.config.allowUnfree = true;
  
  # Font configuration
  fonts.fontconfig = {
    enable = true;
    defaultFonts = {
      monospace = [ "JetBrains Mono" "Hack" "DejaVu Sans Mono" ];
      sansSerif = [ "Source Sans Pro" "DejaVu Sans" ];
      serif = [ "DejaVu Serif" ];
    };
  };
  
  # Git configuration with age secrets
  programs.git = {
    userName = "Your Name"; # Will be overridden by age secrets
    userEmail = "your.email@example.com"; # Will be overridden by age secrets
  };
  
  # Shell configuration - ZSH ONLY
  programs.zsh = {
    enable = true;
    shellAliases = {
      # Git aliases with age secrets
      git-commit = ''git -c user.name="$(age-get-secret git-name 2>/dev/null || echo 'Your Name')" -c user.email="$(age-get-secret git-email 2>/dev/null || echo 'your.email@example.com')" commit'';
      git-commit-signed = ''git -c user.name="$(age-get-secret git-name 2>/dev/null || echo 'Your Name')" -c user.email="$(age-get-secret git-email 2>/dev/null || echo 'your.email@example.com')" commit -S'';
      
      # Terminal switching aliases
      use-xterm = "export TERMINAL=xterm && echo 'Default terminal set to xterm'";
      use-urxvt = "export TERMINAL=urxvt && echo 'Default terminal set to urxvt'";
      use-wezterm = "export TERMINAL=wezterm && echo 'Default terminal set to wezterm'";
      
      # Quick terminal launchers
      xterm-test = "term-xterm";
      urxvt-test = "term-urxvt";
      wezterm-test = "term-wezterm";
      
      # i3 Xephyr launcher (easy to remember)
      i3 = "startx";
      start-i3 = "startx";
    };
  };
  
  # Common applications for all machines
  home.packages = with pkgs; [
    # Core applications (available on all machines)
    git
    
    # Desktop applications (will work on all machines with i3+Xephyr)  
    nautilus       # File manager
    _1password     # Password manager
    keybase        # Keybase client
    charm          # Development tools
    
    # i3 and Xephyr dependencies
    xorg.xorgserver  # Provides Xephyr
    rofi             # Application launcher
    
    # Terminal options
    xterm            # Default terminal (lightweight)
    rxvt-unicode     # Alternative terminal (customizable)
    wezterm          # Modern terminal (GPU-accelerated)
    
    # WSL/i3 utilities
    xclip            # Clipboard integration
    i3-resurrect     # Session saving/restoring
    xorg.xrdb        # X resource database
    xorg.xkill       # Kill X applications
    xorg.xrandr      # Display information (for startx script)
    feh              # Background image setter
    picom            # Compositor
    dunst            # Notification daemon
    
    # Terminal info and utilities
    ncurses          # Terminal capabilities
    procps           # For pkill command in startx script
    
    # Fonts for proper display
    meslo-lgs-nf                    # Powerline font
    emacs-all-the-icons-fonts       # Icons for treemacs and other Emacs packages
    jetbrains-mono                  # Programming font
    fira-code                       # Programming font with ligatures
    hack-font                       # Clean monospace font
    iosevka                         # Narrow programming font
    victor-mono                     # Cursive programming font
    nerd-fonts.hack                 # Nerd Font version of Hack
    dejavu_fonts                    # Standard fonts
    noto-fonts                      # Unicode fonts
    noto-fonts-emoji                # Emoji fonts
    source-sans-pro                 # Sans serif font
    
    # Terminal wrapper scripts for easy switching
    (writeShellScriptBin "term-xterm" ''
      exec ${xterm}/bin/xterm -fa "JetBrains Mono" -fs 10 -e ${zsh}/bin/zsh "$@"
    '')
    
    (writeShellScriptBin "term-urxvt" ''
      ${xorg.xrdb}/bin/xrdb -merge ~/.Xresources 2>/dev/null || true
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
    
    # Xephyr i3 launcher (renamed from i3-xephyr to startx) - RESTORED ORIGINAL WORKING VERSION
    (writeShellScriptBin "startx" ''
      #!/usr/bin/env bash

      # i3-xephyr: Launch i3 window manager in a nested X server using Xephyr
      # This allows running i3 on systems where another window manager is already running

      # Find an available display number
      DISPLAY_NUM=1
      while [ -S "/tmp/.X11-unix/X$DISPLAY_NUM" ] || [ -f "/tmp/.X$DISPLAY_NUM-lock" ]; do
          DISPLAY_NUM=$((DISPLAY_NUM + 1))
      done

      XEPHYR_DISPLAY=":$DISPLAY_NUM"

      # Auto-detect display size and use 80% of it
      DISPLAY_INFO=$(${xorg.xrandr}/bin/xrandr | grep ' connected' | head -1 | grep -o '[0-9]*x[0-9]*')
      if [ -n "$DISPLAY_INFO" ]; then
          WIDTH=$(echo $DISPLAY_INFO | cut -d'x' -f1)
          HEIGHT=$(echo $DISPLAY_INFO | cut -d'x' -f2)
          # Use 80% of display size
          SCREEN_WIDTH=$((WIDTH * 80 / 100))
          SCREEN_HEIGHT=$((HEIGHT * 80 / 100))
          SCREEN_SIZE="$SCREEN_WIDTH"x"$SCREEN_HEIGHT"
      else
          # Fallback size
          SCREEN_SIZE="1400x900"
      fi

      echo "Using display $XEPHYR_DISPLAY with size $SCREEN_SIZE"

      # Kill any existing Xephyr instance on our display
      ${pkgs.procps}/bin/pkill -f "Xephyr.*:$DISPLAY_NUM"

      # Start Xephyr in the background with higher DPI for larger fonts and resizable window
      ${xorg.xorgserver}/bin/Xephyr "$XEPHYR_DISPLAY" -ac -host-cursor -reset -terminate -dpi 144 -screen "$SCREEN_SIZE" -resizeable &
      XEPHYR_PID=$!

      # Wait for Xephyr to start
      sleep 3

      # Check if Xephyr is running
      if ! kill -0 $XEPHYR_PID 2>/dev/null; then
          echo "Failed to start Xephyr"
          exit 1
      fi

      # Start i3 in the nested X server
      echo "Starting i3 on display $XEPHYR_DISPLAY..."
      DISPLAY="$XEPHYR_DISPLAY" ${i3}/bin/i3 &
      I3_PID=$!

      # Wait a bit for i3 to start
      sleep 2

      # i3 is now running with the keybinding from config

      # Focus the Xephyr window by starting a simple application
      DISPLAY="$XEPHYR_DISPLAY" ${xterm}/bin/xterm -fa "DejaVu Sans Mono" -fs 10 -e "echo 'i3 workspace ready. Use Alt+Enter for terminal, Alt+d for dmenu, Alt+p for rofi'; sleep 2" &

      # Function to cleanup on exit
      cleanup() {
          echo "Cleaning up..."
          [ -n "$I3_PID" ] && kill "$I3_PID" 2>/dev/null
          [ -n "$XEPHYR_PID" ] && kill "$XEPHYR_PID" 2>/dev/null
          exit 0
      }

      # Set up signal handlers
      trap cleanup SIGINT SIGTERM

      echo "i3 running in Xephyr on display $XEPHYR_DISPLAY"
      echo "Press Ctrl+C to exit"

      # Wait for processes to finish
      wait $I3_PID
      cleanup
    '')
  ];

  # Terminal configurations for easy switching
  
  # .Xresources for rxvt-unicode (based on your WSL config)
  home.file.".Xresources".text = ''
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
    URxvt.color4:       #5f819d
    URxvt.color12:      #81a2be

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
    URxvt.font: xft:JetBrains Mono:size=10
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
    config.font_size = 10.0

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