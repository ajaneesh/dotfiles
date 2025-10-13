{ config, pkgs, lib, ... }:

{
  options = {
    i3.enable = lib.mkEnableOption "i3 window manager";
  };

  config = lib.mkIf config.i3.enable {
    xsession.enable = true;

    home.file.".local/share/xsessions/i3.desktop".text = ''
      [Desktop Entry]
      Name=i3
      Comment=improved dynamic tiling window manager
      Exec=i3
      Type=Application
    '';

    # Advanced i3 configuration with Emacs integration and terminal switching

    # Configure fontconfig for proper monospace fonts
    fonts.fontconfig.enable = true;

    home.file.".config/fontconfig/conf.d/10-monospace.conf".text = ''
      <?xml version="1.0"?>
      <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
      <fontconfig>
        <alias>
          <family>monospace</family>
          <prefer>
            <family>JetBrains Mono</family>
            <family>DejaVu Sans Mono</family>
          </prefer>
        </alias>
      </fontconfig>
    '';

    # Install required packages
    home.packages = with pkgs; [
      i3
      i3status
      dmenu
      rofi
      xdotool          # For window manipulation
      # X11 fonts
      xorg.fontmiscmisc
      xorg.fontutil
      i3-resurrect
      xorg.xrdb
      xorg.xkill
      xorg.xrandr
      xorg.xset
      feh
      picom
      dunst
      # Simple lock script using system i3lock (has proper setuid permissions)
      (pkgs.writeShellScriptBin "lock-screen" ''
        # Show a message before locking
        ${pkgs.libnotify}/bin/notify-send "Locking screen..." "Type your password and press Enter to unlock" -t 2000 || true

        # Use system i3lock (installed via apt) which has proper PAM permissions
        /usr/bin/i3lock -n -c 000000
      '')
    ];

    # Advanced i3 configuration using Home Manager's native module
    xsession.windowManager.i3 = {
      enable = true;
      config = {
        modifier = "Mod1"; # Alt key
        
        # Basic startup applications
        startup = [
          # Set wallpaper if available
          { command = "feh --bg-fill ~/.config/wallpaper.jpg 2>/dev/null || true"; always = true; notification = false; }
        ];
        
        # Simple default layout
        workspaceLayout = "tabbed";
        
        # Window decoration settings
        window = {
          border = 1;
          titlebar = false;
        };
        
        # Font configuration
        fonts = {
          names = [ "pango:Source Sans Pro" ];
          size = 8.0;
        };
        
        # Advanced key bindings with Emacs integration and terminal switching
        keybindings = let modifier = "Mod1"; in {
          # Terminal launcher with logical progression
          "${modifier}+Return" = "exec --no-startup-id term-urxvt";
          "${modifier}+Shift+Return" = "exec --no-startup-id term-xterm";
          "${modifier}+Ctrl+Return" = "exec --no-startup-id term-wezterm";

          # Application launcher - Linux binaries only, no Windows executables
          "${modifier}+d" = "exec --no-startup-id env GDK_BACKEND=x11 PATH=\"$HOME/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin:/usr/local/bin:/usr/bin:/bin\" ${pkgs.rofi}/bin/rofi -modes run -show run";

          # Window management
          "${modifier}+Shift+x" = "kill";
          "${modifier}+Shift+q" = "kill"; # Alternative for muscle memory
          "${modifier}+Shift+f" = "fullscreen toggle global";
          "${modifier}+f" = "fullscreen toggle";

          # Window navigation (standard i3)
          "${modifier}+Left" = "focus left";
          "${modifier}+Down" = "focus down";
          "${modifier}+Up" = "focus up";
          "${modifier}+Right" = "focus right";
          
          # Window navigation (vim keys - conflicts with Emacs handled by modes)
          "${modifier}+j" = "focus left";
          "${modifier}+k" = "focus down";
          "${modifier}+l" = "focus up";
          "${modifier}+semicolon" = "focus right";
          
          # Moving windows
          "${modifier}+Shift+Left" = "move left";
          "${modifier}+Shift+Down" = "move down";
          "${modifier}+Shift+Up" = "move up";
          "${modifier}+Shift+Right" = "move right";
          
          # Resize window with vim keys
          "${modifier}+Shift+h" = "resize shrink width 5 px or 5 ppt";
          "${modifier}+Shift+j" = "resize grow height 5 px or 5 ppt";
          "${modifier}+Shift+k" = "resize shrink height 5 px or 5 ppt";
          "${modifier}+Shift+l" = "resize grow width 5 px or 5 ppt";

          # Workspace management
          "${modifier}+1" = "workspace 1";
          "${modifier}+2" = "workspace 2";
          "${modifier}+3" = "workspace 3";
          "${modifier}+4" = "workspace 4";
          "${modifier}+5" = "workspace 5";
          "${modifier}+6" = "workspace 6";
          "${modifier}+7" = "workspace 7";
          "${modifier}+8" = "workspace 8";
          "${modifier}+9" = "workspace 9";
          "${modifier}+0" = "workspace 10";

          # Move container to workspace
          "${modifier}+Shift+1" = "move container to workspace 1";
          "${modifier}+Shift+2" = "move container to workspace 2";
          "${modifier}+Shift+3" = "move container to workspace 3";
          "${modifier}+Shift+4" = "move container to workspace 4";
          "${modifier}+Shift+5" = "move container to workspace 5";
          "${modifier}+Shift+6" = "move container to workspace 6";
          "${modifier}+Shift+7" = "move container to workspace 7";
          "${modifier}+Shift+8" = "move container to workspace 8";
          "${modifier}+Shift+9" = "move container to workspace 9";
          "${modifier}+Shift+0" = "move container to workspace 10";
          
          # Layouts
          "${modifier}+h" = "split h";
          "${modifier}+v" = "split v";
          "${modifier}+s" = "layout stacking";
          "${modifier}+w" = "layout tabbed";
          "${modifier}+e" = "layout toggle split";
          
          # Floating
          "${modifier}+Shift+space" = "floating toggle";
          "${modifier}+space" = "focus mode_toggle";
          
          # Session management
          "${modifier}+Shift+c" = "reload";
          "${modifier}+Shift+r" = "restart";
          "${modifier}+Shift+s" = "exec --no-startup-id i3-resurrect save";
          "${modifier}+Shift+t" = "exec --no-startup-id i3-resurrect restore";

          # Mode switching for Emacs integration
          "${modifier}+Escape" = "mode default";
          "${modifier}+ctrl+0" = "mode emacs";

          # Lock screen
          "${modifier}+Shift+z" = "exec --no-startup-id lock-screen";

          # Exit
          "${modifier}+Shift+e" = "exec i3-nagbar -t warning -m 'Exit i3?' -B 'Yes' 'i3-msg exit'";

          # Xephyr-specific: Refresh display after window resize
          "${modifier}+Shift+F5" = "exec --no-startup-id xrandr -q";
        };

        # Advanced mode system for Emacs integration
        modes = {
          # Emacs-friendly mode with alternative keybindings
          "emacs" = let 
              modifier = "Mod1";
          in {	    
              # Alternative window navigation (doesn't conflict with Emacs)
              "${modifier}+bracketleft" = "focus left";     # Alt+[
              "${modifier}+bracketright" = "focus right";   # Alt+] 
              "${modifier}+minus" = "focus up";             # Alt+-
              "${modifier}+equal" = "focus down";           # Alt+=
              
              # Alternative navigation using arrow keys (always safe)
              "${modifier}+Left" = "focus left";
              "${modifier}+Right" = "focus right";
              "${modifier}+Up" = "focus up";
              "${modifier}+Down" = "focus down";
          
              # Workspaces still work normally
              "${modifier}+1" = "workspace 1; mode default";
              "${modifier}+2" = "workspace 2; mode default";
              "${modifier}+3" = "workspace 3; mode default";
              "${modifier}+4" = "workspace 4; mode default";
              "${modifier}+5" = "workspace 5; mode default";
              "${modifier}+6" = "workspace 6; mode default";
              "${modifier}+7" = "workspace 7; mode default";
              "${modifier}+8" = "workspace 8; mode default";
              "${modifier}+9" = "workspace 9; mode default";
              "${modifier}+0" = "workspace 10; mode default";
          
              # Exit emacs mode
    	        "${modifier}+Escape" = "mode default";
	            "${modifier}+ctrl+0" = "mode default";
             
          };

          # Standard resize mode
          resize = {
            "Left" = "resize shrink width 10 px";
            "Down" = "resize grow height 10 px";
            "Up" = "resize shrink height 10 px";
            "Right" = "resize grow width 10 px";
            "h" = "resize shrink width 10 px";
            "j" = "resize grow height 10 px";
            "k" = "resize shrink height 10 px";
            "l" = "resize grow width 10 px";
            "Escape" = "mode default";
            "Return" = "mode default";
          };
        };
        
        # Status bar configuration
        bars = [{
          position = "bottom";
          statusCommand = "${pkgs.i3status}/bin/i3status";
          fonts = {
            names = [ "JetBrains Mono" ];
            size = 9.0;
          };
        }];
      };
    };

    # Enhanced i3status configuration
    programs.i3status = {
      enable = true;
      general = {
        colors = true;
        color_good = "#8C9440";
        color_bad = "#A54242";
        color_degraded = "#DE935F";
        interval = 5;
      };
      modules = {
        "load" = {
          position = 1;
          settings = {
            format = "Load: %1min";
          };
        };
        "disk /" = {
          position = 2;
          settings = {
            format = "Disk: %avail";
          };
        };
        "memory" = {
          position = 3;
          settings = {
            format = "Mem: %used/%total";
            threshold_degraded = "1G";
            format_degraded = "Mem LOW: %available";
          };
        };
        "cpu_usage" = {
          position = 4;
          settings = {
            format = "CPU: %usage";
          };
        };
        "tztime local" = {
          position = 5;
          settings = {
            format = "%Y-%m-%d %H:%M:%S";
          };
        };
      };
    };
  };
}