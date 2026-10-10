{ config, pkgs, lib, ... }:

let
  # ===================================================================
  # i3blocks status bar: Nerd Font icons instead of text labels, white
  # text (set via the bar's statusline colour), a VPN padlock that turns
  # yellow+locked when a tunnel is up (white+unlocked otherwise), and a
  # left-clickable Wi-Fi block that opens a rofi network picker. Replaces
  # the old programs.i3status config. Glyphs are FontAwesome-v4 codepoints
  # from Hack Nerd Font (installed in fonts.nix). nmcli is the system
  # (apt) NetworkManager client. Each block prints full_text (+ short_text
  # + colour for the VPN block, per the i3blocks 3-line protocol).
  # ===================================================================

  # Left-click the Wi-Fi block -> pick a network via rofi and connect.
  wifiMenu = pkgs.writeShellScriptBin "wifi-menu" ''
    nmcli device wifi rescan >/dev/null 2>&1
    mapfile -t rows < <(nmcli -t -f IN-USE,SIGNAL,SECURITY,SSID device wifi list 2>/dev/null)
    labels=(); ssids=()
    for r in "''${rows[@]}"; do
      IFS=: read -r inuse signal sec ssid <<< "$r"
      [ -z "$ssid" ] && continue
      mark="  "; [ "$inuse" = "*" ] && mark=" "
      labels+=("$(printf '%s %s  %s%%  %s' "$mark" "$ssid" "$signal" "''${sec:---}")")
      ssids+=("$ssid")
    done
    if [ "''${#ssids[@]}" -eq 0 ]; then
      command -v notify-send >/dev/null 2>&1 && notify-send "Wi-Fi" "No networks found"
      exit 0
    fi
    idx=$(printf '%s\n' "''${labels[@]}" | ${pkgs.rofi}/bin/rofi -dmenu -i -p "Wi-Fi" -format i)
    [ -z "$idx" ] && exit 0
    ssid="''${ssids[$idx]}"
    if nmcli -t -f NAME connection show | grep -qxF "$ssid"; then
      nmcli connection up id "$ssid" >/dev/null 2>&1
    else
      pass=$(${pkgs.rofi}/bin/rofi -dmenu -password -p "Password for $ssid (blank = open)" < /dev/null)
      if [ -n "$pass" ]; then
        nmcli device wifi connect "$ssid" password "$pass" >/dev/null 2>&1
      else
        nmcli device wifi connect "$ssid" >/dev/null 2>&1
      fi
    fi
    command -v notify-send >/dev/null 2>&1 && notify-send "Wi-Fi" "Tried to connect to $ssid"
  '';

  # Wi-Fi block:  + SSID only (no IP). Left-click opens the picker above.
  wifiBlock = pkgs.writeShellScript "i3blocks-wifi" ''
    icon=$(printf '\357\207\253')
    if [ "$BLOCK_BUTTON" = "1" ]; then ${wifiMenu}/bin/wifi-menu >/dev/null 2>&1 & fi
    ssid=$(nmcli -t -f IN-USE,SSID device wifi list 2>/dev/null | awk -F: '$1=="*"{print $2; exit}')
    if [ -n "$ssid" ]; then
      printf '%s %s\n' "$icon" "$ssid"
    else
      printf '%s\n' "$icon"
    fi
  '';

  # VPN block: padlock.  yellow when a VPN connection is active,  white
  # otherwise. Left-click connects (rofi picker over VPN profiles),
  # right-click disconnects the active one.
  vpnBlock = pkgs.writeShellScript "i3blocks-vpn" ''
    active=$(nmcli -t -f NAME,TYPE connection show --active 2>/dev/null | awk -F: '$2=="vpn"{print $1; exit}')
    case "$BLOCK_BUTTON" in
      1) if [ -z "$active" ]; then
           sel=$(nmcli -t -f NAME,TYPE connection show | awk -F: '$2=="vpn"{print $1}' | ${pkgs.rofi}/bin/rofi -dmenu -i -p "VPN")
           [ -n "$sel" ] && nmcli connection up "$sel" >/dev/null 2>&1
         fi ;;
      3) [ -n "$active" ] && nmcli connection down "$active" >/dev/null 2>&1 ;;
    esac
    active=$(nmcli -t -f NAME,TYPE connection show --active 2>/dev/null | awk -F: '$2=="vpn"{print $1; exit}')
    lock=$(printf '\357\200\243'); open=$(printf '\357\202\234')
    if [ -n "$active" ]; then
      printf '%s\n%s\n%s\n' "$lock" "$lock" "#ffff00"
    else
      printf '%s\n%s\n%s\n' "$open" "$open" "#ffffff"
    fi
  '';

  # CPU usage sampled over a short window.
  cpuBlock = pkgs.writeShellScript "i3blocks-cpu" ''
    read -r _ a b c id _ < /proc/stat
    t1=$((a+b+c+id)); i1=$id
    sleep 0.2
    read -r _ a b c id _ < /proc/stat
    t2=$((a+b+c+id)); i2=$id
    dt=$((t2-t1)); di=$((i2-i1))
    if [ "$dt" -gt 0 ]; then u=$((100*(dt-di)/dt)); else u=0; fi
    icon=$(printf '\357\203\244')
    printf '%s %s%%\n' "$icon" "$u"
  '';

  # Battery: only renders when a battery is present (empty -> hidden on desktops).
  batteryBlock = pkgs.writeShellScript "i3blocks-battery" ''
    icon=$(printf '\357\211\200')
    for b in /sys/class/power_supply/BAT*; do
      [ -r "$b/capacity" ] || continue
      printf '%s %s%%\n' "$icon" "$(cat "$b/capacity")"
      exit 0
    done
  '';

  # Left-to-right block order (clock ends up rightmost). Simple stats are
  # inline one-liners; stateful/clickable ones call the scripts above.
  i3blocksConfig = pkgs.writeText "i3blocks.conf" ''
    [wifi]
    command=${wifiBlock}
    interval=10

    [vpn]
    command=${vpnBlock}
    interval=5

    [cpu]
    command=${cpuBlock}
    interval=3

    [memory]
    command=printf '\357\213\233 %s\n' "$(free -h | awk '/^Mem:/{print $3"/"$2}')"
    interval=10

    [disk]
    command=printf '\357\202\240 %s\n' "$(df -h --output=avail / | tail -1 | tr -d ' ')"
    interval=60

    [load]
    command=printf '\357\202\205 %s\n' "$(cut -d' ' -f1 /proc/loadavg)"
    interval=10

    [battery]
    command=${batteryBlock}
    interval=30

    [clock]
    command=printf '\357\200\227 %s\n' "$(date '+%Y-%m-%d %H:%M')"
    interval=30
  '';
in
{
  imports = [
    ./dunst.nix
  ];

  options = {
    i3.enable = lib.mkEnableOption "i3 window manager";
    # Bind Super/Win+L to "lock + switch user" (via the LightDM greeter). Only for
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
      i3blocks         # status-bar engine: Nerd Font icons, clickable blocks
      wifiMenu         # rofi Wi-Fi picker (also bound to the bar's wifi block)
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
      lightlocker      # session locker that uses the LightDM greeter as the lock
                       # screen: one sign-in to return, family can log in, no VT
                       # bypass, and no PAM linkage (the greeter does the auth)

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
          # framebuffer pixels (e.g. the LightDM greeter you logged in from). Try a
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
          # Session locker daemon (native hosts). light-locker uses the SDDM
          # greeter as the lock screen: on lock it switches to the greeter (so any
          # user can log into their own account), returning takes a single
          # sign-in, and the session can't be reached by a VT switch. Guarded so
          # an i3 reload doesn't spawn a second daemon.
          { command = "pgrep -x light-locker >/dev/null || light-locker --lock-on-suspend"; always = true; notification = false; }
        ];
        
        # Simple default layout
        workspaceLayout = "tabbed";
        
        # Window decoration settings
        window = {
          border = 2;
          titlebar = false;
        };

        # Window border colours. i3's default focused border is a faint blue
        # that disappears on a black background; use a bright amber so the
        # active window is unmistakable, and dim the inactive ones hard for
        # contrast. Only border/childBorder show (titlebars are off). Prefer
        # ivory or white? swap #f0c674 for "#fffff0" or "#ffffff".
        colors = {
          focused = {
            border = "#f0c674"; childBorder = "#f0c674"; indicator = "#f0c674";
            background = "#f0c674"; text = "#1d1f21";
          };
          focusedInactive = {
            border = "#1d1f21"; childBorder = "#1d1f21"; indicator = "#1d1f21";
            background = "#1d1f21"; text = "#888888";
          };
          unfocused = {
            border = "#1d1f21"; childBorder = "#1d1f21"; indicator = "#1d1f21";
            background = "#1d1f21"; text = "#888888";
          };
          urgent = {
            border = "#a54242"; childBorder = "#a54242"; indicator = "#a54242";
            background = "#a54242"; text = "#ffffff";
          };
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
          # Lock the machine. light-locker switches to the LightDM greeter, which is
          # the lock screen: sign back in as yourself (single password) to return,
          # or any family member logs into their own account there. Native hosts
          # only (i3.superLock); on WSL/Crostini Win+L reaches the host OS. Both
          # keys do the same thing.
          "Mod4+l" = "exec --no-startup-id light-locker-command --lock";
          "${modifier}+Shift+z" = "exec --no-startup-id light-locker-command --lock";
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
          statusCommand = "${pkgs.i3blocks}/bin/i3blocks -c ${i3blocksConfig}";
          fonts = {
            # Hack Nerd Font Mono supplies the status-bar glyphs; JetBrains Mono
            # stays first for normal text (pango falls back for the icons).
            names = [ "JetBrains Mono" "Hack Nerd Font Mono" ];
            size = 9.0;
          };
          colors = {
            statusline = "#ffffff";   # all block text white (VPN block overrides)
          };
        }];
      };
    };

    # Status bar is i3blocks (see the `let` block at the top of this file for
    # the blocks, icons, VPN padlock, and the clickable Wi-Fi picker). The old
    # programs.i3status config was removed when the bar moved to i3blocks.
  };
}