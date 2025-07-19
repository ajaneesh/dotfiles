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
  
  # Shell configuration - ZSH ONLY with enhanced prompt
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    
    # ZSH plugins for better functionality
    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
        "sudo" 
        "docker"
        "kubectl"
        "systemd"
        "colored-man-pages"
        "command-not-found"
        "history-substring-search"
      ];
      theme = "robbyrussell"; # Clean theme, we'll override with custom prompt
    };
    
    # Enhanced ZSH configuration with git integration
    initContent = ''
      # Git prompt integration
      autoload -Uz vcs_info
      precmd() { vcs_info }
      
      # Git branch info formatting
      zstyle ':vcs_info:git:*' formats ' (%b)'
      zstyle ':vcs_info:*' enable git
      
      # Custom prompt with git branch, current dir, and colors
      setopt PROMPT_SUBST
      PROMPT='%F{cyan}%n@%m%f:%F{blue}%~%f%F{yellow}''${vcs_info_msg_0_}%f$ '
      
      # Right prompt with timestamp
      RPROMPT='%F{240}[%D{%H:%M:%S}]%f'
      
      # Enhanced history configuration
      setopt HIST_VERIFY
      setopt SHARE_HISTORY
      setopt APPEND_HISTORY
      setopt INC_APPEND_HISTORY
      setopt HIST_IGNORE_DUPS
      setopt HIST_IGNORE_SPACE
      setopt HIST_REDUCE_BLANKS
      
      # Better directory navigation
      setopt AUTO_CD
      setopt AUTO_PUSHD
      setopt PUSHD_IGNORE_DUPS
      
      # Case-insensitive completion
      zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
      
      # Keep traditional ls commands working exactly as you expect
      alias ls='ls --color=auto'
      alias ll='ls -alF --color=auto'
      alias la='ls -A --color=auto' 
      alias l='ls -CF --color=auto'
      
      # Add eza as separate modern alternatives (opt-in)
      alias exa='eza --color=auto --icons'
      alias exal='eza -la --color=auto --icons --git --sort=modified'
      alias exat='eza --tree --color=auto --icons'
      alias exaltr='eza -la --color=auto --icons --git --sort=modified'  # Like ls -altr
      
      # Better cat, grep, find
      alias cat='bat --paging=never'
      alias grep='rg'
      alias find='fd'
      
      # Git status shortcuts
      alias gs='git status'
      alias ga='git add'
      alias gd='git diff'
      alias gl='git log --oneline'
      alias gb='git branch'
      alias gc='git checkout'
      alias gp='git pull'
      alias gpu='git push'
      
      # Enhanced terminal utilities
      alias top='btm'           # Better top
      alias ps='procs'          # Better ps
      alias du='dust'           # Better du
      alias man='tldr'          # Better man pages
      
      # FZF alternatives for when preview doesn't work in Xephyr
      alias fzf-simple='fzf --no-preview --height 40% --layout=reverse --border'
      alias fzf-files='fd --type f | fzf-simple'
      alias fzf-dirs='fd --type d | fzf-simple'
      
      # Useful functions
      # Quick file preview
      preview() {
        if [[ -f "$1" ]]; then
          bat --color=always "$1"
        elif [[ -d "$1" ]]; then
          eza --tree --color=always --icons "$1"
        fi
      }
      
      # Find and edit file with fzf
      fe() {
        local file
        file=$(fd --type f | fzf --preview 'bat --color=always --style=header,grid --line-range :300 {}')
        [[ -n "$file" ]] && ''${EDITOR:-vim} "$file"
      }
      
      # Find and cd to directory with fzf
      fcd() {
        local dir
        dir=$(fd --type d | fzf --preview 'tree -C {} | head -200')
        [[ -n "$dir" ]] && cd "$dir"
      }
      
      # Process killer with fzf
      fkill() {
        local pid
        pid=$(procs | fzf --header-lines=1 | awk '{print $1}')
        [[ -n "$pid" ]] && kill -TERM "$pid"
      }
      
      # Enhanced history search (in addition to fzf Ctrl+R)
      bindkey '^[[A' history-substring-search-up
      bindkey '^[[B' history-substring-search-down
      bindkey '^P' history-substring-search-up
      bindkey '^N' history-substring-search-down
      
      # Simple FZF environment - no complex detection that can break
      export FZF_DEFAULT_OPTS="--height=40% --layout=reverse --border"
      
      # Debug info
      alias fzf-debug='echo "Display: $DISPLAY | Terminal: $TERM | Columns: $COLUMNS | Lines: $LINES"'
      
      # FZF key bindings info (shown on first terminal launch)
      if [[ ! -f ~/.fzf_help_shown ]]; then
        echo "🔍 FZF Key Bindings Available:"
        echo "  Ctrl+R  - Search command history"
        echo "  Ctrl+T  - Search files (inserts path) - Preview: Ctrl+/ to toggle"
        echo "  Alt+C   - Search directories (cd into selected)"
        echo ""
        echo "  In FZF: Enter=select, Esc=cancel, Tab=multi-select"
        echo "  Arrow keys or j/k to navigate, Ctrl+/ toggles preview"
        echo ""
        if [[ "$DISPLAY" =~ ^:[0-9]+$ ]]; then
          echo "  📺 Xephyr detected - use 'fzf-debug' if previews don't work"
        fi
        echo ""
        touch ~/.fzf_help_shown
      fi
    '';
    
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
      
      # DPI-specific shortcuts for different displays
      startx-small = "startx --dpi=96";    # Small fonts for high-res displays
      startx-medium = "startx --dpi=120";  # Medium fonts (default)
      startx-large = "startx --dpi=144";   # Large fonts for small displays
      startx-fixed = "startx --no-adaptive-dpi";  # Disable adaptive DPI
    };
    
    # Enhanced history settings
    history = {
      size = 10000;
      save = 10000;
      extended = true;
      ignoreDups = true;
      ignoreSpace = true;
      share = true;
    };
  };
  
  # FZF - Fuzzy finder with ZSH integration - SIMPLIFIED TO WORK
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    # Start with basic config that definitely works
    defaultCommand = "fd --type f";
    defaultOptions = [
      "--height=40%"
      "--layout=reverse"
      "--border"
    ];
    # File widget (Ctrl+T) with preview
    fileWidgetCommand = "fd --type f";  
    fileWidgetOptions = [
      "--preview 'bat --color=always {}'"
      "--preview-window=right:50%"
    ];
    # Directory widget (Alt+C) with simple preview
    changeDirWidgetCommand = "fd --type d";
    changeDirWidgetOptions = [
      "--preview 'ls -la {}'"
      "--preview-window=right:50%"
    ];
    # History widget (Ctrl+R) - no preview
    historyWidgetOptions = [
      "--height=60%"
      "--layout=reverse" 
      "--border"
    ];
  };
  
  # Zoxide - Smart cd replacement  
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };
  
  # Bat - Better cat with syntax highlighting
  programs.bat = {
    enable = true;
    config = {
      theme = "TwoDark";
      style = "numbers,changes,header";
    };
  };
  
  # Common applications for all machines
  home.packages = with pkgs; [
    # Core applications (available on all machines)
    git
    
    # Desktop applications (will work on all machines with i3+Xephyr)  
    nautilus       # File manager
    _1password-cli # Password manager CLI
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
    
    # Modern terminal tools
    fzf              # Fuzzy finder for files, history, processes
    ripgrep          # Modern grep replacement (rg)
    fd               # Modern find replacement  
    bat              # Modern cat replacement with syntax highlighting
    eza              # Modern ls replacement with icons and git integration
    zoxide           # Smart cd replacement (z command)
    tldr             # Better man pages with examples
    tree             # Directory tree visualization
    htop             # Better top replacement
    bottom           # Modern system monitor (btm)
    du-dust          # Better du replacement (dust)
    procs            # Modern ps replacement
    bandwhich        # Network bandwidth monitor
    hyperfine        # Command-line benchmarking tool
    
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
      exec ${xterm}/bin/xterm \
        -fa "JetBrains Mono" -fs 10 \
        -bg "#1d1f21" -fg "#c5c8c6" \
        -cr "#c5c8c6" \
        -e ${zsh}/bin/zsh "$@"
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
    
    # Xephyr i3 launcher (renamed from i3-xephyr to startx) - ENHANCED FOR MULTI-DISPLAY
    (writeShellScriptBin "startx" ''
      #!/usr/bin/env bash

      # Enhanced i3-xephyr: Launch i3 window manager in a nested X server using Xephyr
      # Multi-display aware with adaptive DPI and auto-refresh support

      # Parse command line arguments
      ADAPTIVE_DPI=true
      AUTO_REFRESH=true
      CUSTOM_DPI=""
      
      while [[ $# -gt 0 ]]; do
        case $1 in
          --dpi=*)
            CUSTOM_DPI="''${1#*=}"
            ADAPTIVE_DPI=false
            shift
            ;;
          --no-adaptive-dpi)
            ADAPTIVE_DPI=false
            shift
            ;;
          --no-auto-refresh)
            AUTO_REFRESH=false
            shift
            ;;
          -h|--help)
            echo "Usage: startx [OPTIONS]"
            echo "Options:"
            echo "  --dpi=NUMBER        Set custom DPI (disables adaptive DPI)"
            echo "  --no-adaptive-dpi   Use fixed DPI instead of adaptive"
            echo "  --no-auto-refresh   Disable automatic xrandr refresh"
            echo "  -h, --help          Show this help"
            exit 0
            ;;
          *)
            echo "Unknown option: $1"
            exit 1
            ;;
        esac
      done

      # Find an available display number
      DISPLAY_NUM=1
      while [ -S "/tmp/.X11-unix/X$DISPLAY_NUM" ] || [ -f "/tmp/.X$DISPLAY_NUM-lock" ]; do
          DISPLAY_NUM=$((DISPLAY_NUM + 1))
      done

      XEPHYR_DISPLAY=":$DISPLAY_NUM"

      # Get display information
      DISPLAY_INFO=$(${xorg.xrandr}/bin/xrandr | grep ' connected primary\|^[^ ].*connected' | head -1)
      
      if [ -n "$DISPLAY_INFO" ]; then
          # Extract resolution
          RESOLUTION=$(echo "$DISPLAY_INFO" | grep -o '[0-9]*x[0-9]*' | head -1)
          # Extract physical size for DPI calculation
          PHYSICAL_SIZE=$(echo "$DISPLAY_INFO" | grep -o '[0-9]*mm x [0-9]*mm')
          
          if [ -n "$RESOLUTION" ]; then
              WIDTH=$(echo $RESOLUTION | cut -d'x' -f1)
              HEIGHT=$(echo $RESOLUTION | cut -d'x' -f2)
              # Use 80% of display size
              SCREEN_WIDTH=$((WIDTH * 80 / 100))
              SCREEN_HEIGHT=$((HEIGHT * 80 / 100))
              SCREEN_SIZE="$SCREEN_WIDTH"x"$SCREEN_HEIGHT"
              
              # Calculate adaptive DPI if enabled
              if [ "$ADAPTIVE_DPI" = true ] && [ -n "$PHYSICAL_SIZE" ]; then
                  PHYSICAL_WIDTH=$(echo "$PHYSICAL_SIZE" | cut -d' ' -f1 | sed 's/mm//')
                  if [ -n "$PHYSICAL_WIDTH" ] && [ "$PHYSICAL_WIDTH" -gt 0 ]; then
                      # Calculate DPI: (pixels / mm) * 25.4
                      DPI=$(( (WIDTH * 254) / (PHYSICAL_WIDTH * 10) ))
                      # Clamp DPI to reasonable range (96-200)
                      if [ "$DPI" -lt 96 ]; then DPI=96; fi
                      if [ "$DPI" -gt 200 ]; then DPI=200; fi
                      echo "Calculated DPI: $DPI (from resolution $RESOLUTION, physical size $PHYSICAL_SIZE)"
                  else
                      DPI=120  # Default for adaptive mode
                  fi
              elif [ -n "$CUSTOM_DPI" ]; then
                  DPI="$CUSTOM_DPI"
                  echo "Using custom DPI: $DPI"
              else
                  DPI=120  # Conservative default for multi-display setups
                  echo "Using fixed DPI: $DPI"
              fi
          else
              SCREEN_SIZE="1400x900"
              DPI=120
          fi
      else
          SCREEN_SIZE="1400x900"
          DPI=120
      fi

      echo "Using display $XEPHYR_DISPLAY with size $SCREEN_SIZE, DPI $DPI"

      # Kill any existing Xephyr instance on our display
      ${pkgs.procps}/bin/pkill -f "Xephyr.*:$DISPLAY_NUM"

      # Start Xephyr with calculated DPI and enhanced options
      ${xorg.xorgserver}/bin/Xephyr "$XEPHYR_DISPLAY" \
          -ac \
          -host-cursor \
          -reset \
          -terminate \
          -dpi "$DPI" \
          -screen "$SCREEN_SIZE" \
          -resizeable \
          -retro &
      XEPHYR_PID=$!

      # Wait for Xephyr to start
      sleep 3

      # Check if Xephyr is running
      if ! kill -0 $XEPHYR_PID 2>/dev/null; then
          echo "Failed to start Xephyr"
          exit 1
      fi

      # Set up the nested display environment
      export NESTED_DISPLAY="$XEPHYR_DISPLAY"

      # Start i3 in the nested X server
      echo "Starting i3 on display $XEPHYR_DISPLAY..."
      DISPLAY="$XEPHYR_DISPLAY" ${i3}/bin/i3 &
      I3_PID=$!

      # Wait a bit for i3 to start
      sleep 2

      # Set up auto-refresh if enabled
      if [ "$AUTO_REFRESH" = true ]; then
          # Background process to monitor for window resizes and auto-refresh
          (
              while kill -0 $XEPHYR_PID 2>/dev/null; do
                  sleep 5
                  # Refresh the display to fix canvas expansion issues
                  DISPLAY="$XEPHYR_DISPLAY" ${xorg.xrandr}/bin/xrandr -q >/dev/null 2>&1 || true
              done
          ) &
          REFRESH_PID=$!
      fi

      # Focus the Xephyr window by starting a simple application
      DISPLAY="$XEPHYR_DISPLAY" ${xterm}/bin/xterm -fa "JetBrains Mono" -fs 10 -e "echo 'i3 workspace ready. DPI: $DPI | Use Alt+Enter for terminal, Alt+d for dmenu, Alt+p for rofi | Alt+Shift+F5 to refresh display'; sleep 3" &

      # Function to cleanup on exit
      cleanup() {
          echo "Cleaning up..."
          [ -n "$REFRESH_PID" ] && kill "$REFRESH_PID" 2>/dev/null
          [ -n "$I3_PID" ] && kill "$I3_PID" 2>/dev/null
          [ -n "$XEPHYR_PID" ] && kill "$XEPHYR_PID" 2>/dev/null
          exit 0
      }

      # Set up signal handlers
      trap cleanup SIGINT SIGTERM

      echo "i3 running in Xephyr on display $XEPHYR_DISPLAY (DPI: $DPI)"
      echo "Auto-refresh: $AUTO_REFRESH | Adaptive DPI: $ADAPTIVE_DPI"
      echo "Press Ctrl+C to exit"
      echo ""
      echo "Tips:"
      echo "- Use 'startx --dpi=96' for smaller fonts"
      echo "- Use 'startx --dpi=144' for larger fonts" 
      echo "- Use Alt+Shift+F5 inside i3 to manually refresh display"

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