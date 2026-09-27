{ config, pkgs, lib, ... }:

{
  imports = [
    ./dunst.nix
  ];

  options = {
    i3.enable = lib.mkEnableOption "i3 window manager";
    # Bind Super/Win+L to "lock + switch user" (via the SDDM greeter). Only for
    # NATIVE hosts (Debian/Ubuntu) where i3 is the top layer and there is no host
    # OS to hand Win+L to. On WSL/Crostini leave this off so Win+L cascades to
    # the host (Windows/ChromeOS), which locks the whole thing.
    i3.superLock = lib.mkEnableOption "bind Super+L to lock-and-switch-user (native SDDM hosts)";
  };

  config = lib.mkIf config.i3.enable {
    # Enable dunst notifications for i3
    dunst.enable = true;

    xsession.enable = true;

    # NB: display-manager session registration is NOT done here. SDDM only
    # scans /usr/{local/,}share/xsessions (root dirs), never ~/.local/share/
    # xsessions, so a home.file there is dead weight. The "i3 (home-manager)"
    # session is installed by the `x11-setup` helper in native-x-session.nix.

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
      jgmenu           # cascading, categorized XDG app menu (Alt+a)
      xdotool          # For window manipulation
      # X11 fonts
      font-misc-misc
      font-util
      i3-resurrect
      xrdb
      xkill
      xrandr
      xset
      xprop       # For WM debugging
      feh
      picom
      xss-lock         # logind-integrated locker driver (runs the locker on lock)
      # NB: the locker itself is the SYSTEM /usr/bin/i3lock (apt) - a Nix locker
      # can't authenticate via PAM on non-NixOS. imagemagick blurs the backdrop.
      imagemagick
      # The lock screen. IMPORTANT: it locks with the SYSTEM i3lock (/usr/bin/
      # i3lock, from apt), NOT a Nix locker - a Nix-built PAM app links Nix's
      # libpam, which can't find the distro's PAM modules on non-NixOS, so it can
      # never authenticate. To avoid a blank screen we freeze the current display,
      # blur+darken it, and label it, then feed that image to i3lock -i. --nofork
      # so xss-lock can track it.
      (pkgs.writeShellScriptBin "screen-lock" ''
        img="$(mktemp --suffix=.png)"
        ${pkgs.imagemagick}/bin/import -window root "$img" 2>/dev/null || true
        if [ -s "$img" ]; then
          ${pkgs.imagemagick}/bin/convert "$img" -blur 0x8 -brightness-contrast -12x0 \
            -gravity center -pointsize 42 -font DejaVu-Sans -fill '#eceff4' \
            -annotate +0+0 'Locked — type your password to unlock' "$img"
          /usr/bin/i3lock --nofork -i "$img"
        else
          /usr/bin/i3lock --nofork -c 1d1f21
        fi
        rm -f "$img"
      '')

      # Switch user (shared/family machine): LOCK this session (logind ->
      # xss-lock -> i3lock), then drop to the SDDM greeter so another account can
      # log in on its own VT. Because the session is locked, switching to its VT
      # shows i3lock - no bypass. Uses SDDM's DisplayManager seat interface.
      (pkgs.writeShellScriptBin "switch-user" ''
        ${pkgs.systemd}/bin/loginctl lock-session
        seat="''${XDG_SEAT_PATH:-/org/freedesktop/DisplayManager/Seat0}"
        exec ${pkgs.systemd}/bin/busctl --system call \
          org.freedesktop.DisplayManager "$seat" \
          org.freedesktop.DisplayManager.Seat SwitchToGreeter
      '')

      # Cheat-sheet for when you've been away from this machine: list every
      # keybinding, parsed from the *live* generated config so it can never drift
      # from what's actually bound. Mod1 is shown as Alt. Discoverable via
      # `setup-status`.
      (pkgs.writeShellScriptBin "i3-keys" ''
        cfg="$HOME/.config/i3/config"
        if [ ! -f "$cfg" ]; then
          echo "No i3 config found at $cfg" >&2
          exit 1
        fi
        echo
        echo "i3 keybindings   (Mod = Alt)"
        echo "============================"
        echo
        echo "Default mode"
        ${pkgs.gawk}/bin/awk '
          function clean(s) {
            gsub(/^[ \t]*bindsym[ \t]+/, "", s)
            gsub(/--release[ \t]+/, "", s)
            gsub(/Mod1/, "Alt", s)
            gsub(/exec[ \t]+(--no-startup-id[ \t]+)?/, "", s)
            return s
          }
          /^mode[ \t]/ {
            name = $0
            sub(/^mode[ \t]+/, "", name)
            sub(/[ \t]*\{[ \t]*$/, "", name)
            gsub(/^"|"$/, "", name)
            printf "\nMode: %s\n", name
            next
          }
          /^[ \t]*bindsym/ {
            line = clean($0)
            key = line; sub(/[ \t].*/, "", key)
            act = line; sub(/^[^ \t]+[ \t]+/, "", act)
            printf "  %-26s %s\n", key, act
          }
        ' "$cfg"
        echo
      '')
    ];

    # Appearance for the jgmenu app menu (Alt+a): a compact dark overlay at the
    # pointer. Colours match the Tomorrow Night palette used elsewhere. Unknown
    # keys are ignored by jgmenu, so this is safe across versions.
    xdg.configFile."jgmenu/jgmenurc".text = ''
      # Resident daemon: start hidden, stay alive after closing, and un-hide on a
      # USR1 signal (Alt+a). This avoids jgmenu's grab-on-launch race under i3
      # (where launching it from the keybinding made it close instantly).
      stay_alive      = 1
      hide_on_startup = 1
      # Build the menu from XDG .desktop files (nix + apt apps), categorized.
      csv_cmd         = ${pkgs.jgmenu}/lib/jgmenu/jgmenu-apps
      menu_width     = 240
      menu_border    = 1
      menu_radius    = 4
      item_height    = 26
      item_padding_x = 8
      font           = Source Sans Pro 10
      icon_size      = 22
      position_mode  = pointer
      # jgmenu colours use the format "#rrggbb aaa" where aaa is alpha as a
      # PERCENT (0-100). An 8-digit #rrggbbaa is NOT parsed - it silently yields
      # invisible text (menu showed icons only).
      color_menu_bg  = #1d1f21 100
      color_norm_fg  = #c5c8c6 100
      color_sel_bg   = #373b41 100
      color_sel_fg   = #ffffff 100
      color_border   = #373b41 100
    '';

    # Advanced i3 configuration using Home Manager's native module
    xsession.windowManager.i3 = {
      enable = true;
      config = {
        modifier = "Mod1"; # Alt key
        
        # Basic startup applications
        startup = [
          # Set the session-wide DPI (Xft.dpi) from display.scale before anything
          # else, so every Xft app (urxvt, xterm, rofi, dmenu, Emacs, GTK) scales
          # from the one knob. See modules/common/display.nix.
          { command = "display-apply"; always = true; notification = false; }

          # Paint the root window on every (re)start. i3 never draws the root
          # itself, so without this the uncovered desktop keeps showing leftover
          # framebuffer pixels (e.g. the SDDM greeter you logged in from). Try a
          # wallpaper image; fall back to a solid colour so a missing image can
          # never leave the greeter "ghost" behind.
          { command = "${pkgs.feh}/bin/feh --bg-fill ~/.config/wallpaper.jpg 2>/dev/null || ${pkgs.xsetroot}/bin/xsetroot -solid '#1d1f21'"; always = true; notification = false; }

          # Resident (hidden) jgmenu app menu; Alt+a un-hides it via USR1. Guarded
          # so an i3 reload (Alt+Shift+r) starts it if it isn't running, without
          # ever spawning a duplicate. Also clears a stale ~/.jgmenu-lockfile that
          # jgmenu leaves behind when killed (otherwise it fatally refuses to
          # start, thinking an instance is already running).
          { command = "pgrep jgmenu >/dev/null || { rm -f ~/.jgmenu-lockfile; jgmenu; }"; always = true; notification = false; }
        ] ++ lib.optionals config.i3.superLock [
          # Logind-integrated screen locker (native hosts). xss-lock runs the
          # setuid apt i3lock whenever the session is locked (loginctl
          # lock-session, idle, suspend, or switch-user), so the session is held
          # like a full desktop and a VT switch to it hits the lock - no bypass.
          # Guarded so an i3 reload doesn't spawn a second xss-lock.
          { command = "pgrep -x xss-lock >/dev/null || xss-lock -- screen-lock"; always = true; notification = false; }
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
          # Terminal launchers. Primary is wezterm (rich; GPU on native, software
          # rendering on WSL/Xephyr/Crostini); urxvt/xterm remain as fallbacks.
          "${modifier}+Return" = "exec --no-startup-id term-wezterm";
          "${modifier}+Shift+Return" = "exec --no-startup-id term-urxvt";
          "${modifier}+Ctrl+Return" = "exec --no-startup-id term-xterm";

          # Application launcher - Linux binaries only, no Windows executables
          "${modifier}+d" = "exec --no-startup-id env GDK_BACKEND=x11 PATH=\"$HOME/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin:/usr/local/bin:/usr/bin:/bin\" ${pkgs.rofi}/bin/rofi -modes run -show run";

          # Cascading, categorized app menu. A resident jgmenu daemon (started
          # hidden at login, see startup) is un-hidden by a USR1 signal - which
          # avoids the grab-on-launch race that made a direct launch close
          # instantly under i3. Esc/selection hides it again.
          # (substring match, not -x: the nix-wrapped process is '.jgmenu-wrapped')
          "${modifier}+a" = "exec --no-startup-id pkill -USR1 jgmenu";

          # Window management
          "${modifier}+Shift+x" = "kill";
          "${modifier}+Shift+q" = "kill"; # Alternative for muscle memory
          # Force-kill a frozen window: turns the cursor into an X, click the
          # window to kill its client. Use when a graceful `kill` won't work.
          "${modifier}+Ctrl+Shift+q" = "exec --no-startup-id xkill";
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

          # Enter resize mode (arrows / hjkl to resize, Esc or Return to exit)
          "${modifier}+r" = "mode resize";

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

          # Screenshot to clipboard
          "${modifier}+Shift+equal" = "exec --no-startup-id screenshot-clip";
          "${modifier}+Shift+plus" = "exec --no-startup-id screenshot-clip";

          # Exit -- enter a keyboard-driven confirmation mode (no mouse-only
          # i3-nagbar). The mode name below doubles as the on-screen prompt.
          "${modifier}+Shift+e" = ''mode "(e) exit i3   (Esc) cancel"'';

          # Xephyr-specific: Refresh display after window resize
          "${modifier}+Shift+F5" = "exec --no-startup-id xrandr -q";
        } // lib.optionalAttrs config.i3.superLock {
          # Super/Win+L -> lock this session AND drop to the SDDM greeter so a
          # family member can log into another account (native hosts only; set by
          # i3.superLock). Left unbound on WSL/Crostini so Win+L cascades to the
          # host OS instead. The session is genuinely locked (xss-lock + i3lock),
          # so switching to its VT shows the lock - no bypass.
          "Mod4+l" = "exec --no-startup-id switch-user";

          # Plain lock (no user switch): logind lock -> xss-lock -> i3lock.
          # Single password to unlock; secure against VT switching.
          "${modifier}+Shift+z" = "exec --no-startup-id loginctl lock-session";
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

          # Keyboard-driven exit confirmation (replaces the mouse-only
          # i3-nagbar). Name must match the "mode ..." string in the Alt+Shift+e
          # binding above; it is shown as the prompt in the status bar.
          "(e) exit i3   (Esc) cancel" = {
            "e" = "exit";
            "Escape" = "mode default";
            "Return" = "mode default";
            "q" = "mode default";
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