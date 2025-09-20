{ config, pkgs, lib, ... }:

{
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
      # Disable bracketed paste mode to prevent paste warnings
      unset zle_bracketed_paste

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
      startx-small = "startx --dpi=88";    # Small fonts for high-res displays
      startx-medium = "startx --dpi=110";  # Medium fonts (default)
      startx-large = "startx --dpi=132";   # Large fonts for small displays
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

  home.packages = with pkgs; [
    # Modern terminal tools
    ripgrep          # Modern grep replacement (rg)
    fd               # Modern find replacement  
    eza              # Modern ls replacement with icons and git integration
    tldr             # Better man pages with examples
    tree             # Directory tree visualization
    htop             # Better top replacement
    bottom           # Modern system monitor (btm)
    du-dust          # Better du replacement (dust)
    procs            # Modern ps replacement
    bandwhich        # Network bandwidth monitor
    hyperfine        # Command-line benchmarking tool
  ];
}
