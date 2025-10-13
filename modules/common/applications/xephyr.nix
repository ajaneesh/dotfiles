{ config, pkgs, lib, ... }:

{
  imports = [ ./i3.nix ];

  options = {
    xephyr.enable = lib.mkEnableOption "Xephyr session for i3";
  };

  config = lib.mkIf config.xephyr.enable {
    # When xephyr is on, i3 should be on
    i3.enable = true;

    home.packages = with pkgs; [
      # i3/Xephyr utilities
      xclip
      xsel
      autocutsel
      xorg.xorgserver
      procps # For pkill in startx

      (import ../../../apps/restartx.nix { inherit pkgs; })
      (writeShellScriptBin "wsl-x11-recover" ''
        #!/usr/bin/env bash
        echo "WSL X11 Connection Recovery Utility"
        echo "Checking WSLg status..."
        
        # Check if WSLg is running
        if ! pgrep -f "wslg" > /dev/null; then
            echo "WSLg not running. Please restart WSL or check Windows WSL service."
            exit 1
        fi
        
        # Wait for X11 socket
        echo "Waiting for X11 socket..."
        timeout=30
        while [ $timeout -gt 0 ] && [ ! -S "/tmp/.X11-unix/X0" ] && [ ! -S "/tmp/.X11-unix/X1" ]; do
            sleep 1
            timeout=$((timeout - 1))
        done
        
        if [ $timeout -eq 0 ]; then
            echo "Timeout waiting for X11 socket. WSLg may not be properly initialized."
            exit 1
        fi
        
        # Test X11 connection
        export DISPLAY=:0
        if ${pkgs.xorg.xrandr}/bin/xrandr -q > /dev/null 2>&1; then
            echo "X11 connection on :0 is working"
        else
            export DISPLAY=:1
            if ${pkgs.xorg.xrandr}/bin/xrandr -q > /dev/null 2>&1; then
                echo "X11 connection on :1 is working"
            else
                echo "X11 connection failed on both :0 and :1"
                exit 1
            fi
        fi
        
        echo "WSLg X11 connection is healthy. You can now restart Xephyr."
        echo "Run: startx"
      '')
      (writeShellScriptBin "startx" ''
        #!/usr/bin/env bash

        # Enhanced i3-xephyr: Launch i3 window manager in a nested X server using Xephyr
        # Multi-display aware with adaptive DPI and auto-refresh support

        # Check WSLg availability before starting
        echo "Checking WSLg X11 server..."
        if [ ! -S "/tmp/.X11-unix/X0" ] && [ ! -S "/tmp/.X11-unix/X1" ]; then
            echo "ERROR: No X11 socket found. WSLg may not be running."
            echo "Try: wsl --shutdown (from Windows), then restart WSL"
            exit 1
        fi

        # Test basic X11 connection
        export DISPLAY=:0
        if ! ${pkgs.xorg.xrandr}/bin/xrandr -q >/dev/null 2>&1; then
            export DISPLAY=:1  
            if ! ${pkgs.xorg.xrandr}/bin/xrandr -q >/dev/null 2>&1; then
                echo "ERROR: Cannot connect to X11 server on :0 or :1"
                echo "WSLg X server may be crashed. Try restarting WSL."
                exit 1
            fi
        fi
        echo "WSLg X11 connection verified on $DISPLAY"

        # Parse command line arguments
        ADAPTIVE_DPI=true
        AUTO_REFRESH=true
        CUSTOM_DPI="''${1#*=}"
        
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
        DISPLAY_INFO=$(${pkgs.xorg.xrandr}/bin/xrandr | grep ' connected primary|^[^ ].*connected' | head -1)
        
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
        ${pkgs.xorg.xorgserver}/bin/Xephyr "$XEPHYR_DISPLAY" \
            -ac \
            -reset \
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

        # Set cursor theme to fix invisible cursor issue
        DISPLAY="$XEPHYR_DISPLAY" ${pkgs.xorg.xrdb}/bin/xrdb -merge << 'EOF'
        Xcursor.theme: DMZ-White
        Xcursor.size: 16
        *cursorColor: white
        *cursorBlink: true
        EOF
        
        # Also set environment variables for cursor theme
        export XCURSOR_THEME=DMZ-White
        export XCURSOR_SIZE=16

        # Start i3 in the nested X server
        echo "Starting i3 on display $XEPHYR_DISPLAY..."

        # Set up XDG config home for proper config file discovery
        export XDG_CONFIG_HOME="$HOME/.config"

        # Set up fontconfig environment to prevent errors
        export FONTCONFIG_FILE="${pkgs.fontconfig.out}/etc/fonts/fonts.conf"
        export FONTCONFIG_PATH="${pkgs.fontconfig.out}/etc/fonts"

        # Create log directory for i3 debugging
        I3_LOG_DIR="$HOME/.local/share/i3/logs"
        mkdir -p "$I3_LOG_DIR"
        I3_LOG_FILE="$I3_LOG_DIR/i3-$XEPHYR_DISPLAY-$(date +%Y%m%d-%H%M%S).log"
        echo "i3 log file: $I3_LOG_FILE"

        # Start clipboard synchronization between host (:0) and Xephyr display
        DISPLAY=":0" ${pkgs.autocutsel}/bin/autocutsel -fork -selection PRIMARY
        DISPLAY=":0" ${pkgs.autocutsel}/bin/autocutsel -fork -selection CLIPBOARD
        DISPLAY="$XEPHYR_DISPLAY" ${pkgs.autocutsel}/bin/autocutsel -fork -selection PRIMARY
        DISPLAY="$XEPHYR_DISPLAY" ${pkgs.autocutsel}/bin/autocutsel -fork -selection CLIPBOARD
        
        # Start bidirectional clipboard bridge between host and Xephyr
        (
          LAST_HOST_CLIPBOARD=""
          LAST_XEPHYR_CLIPBOARD=""
          
          while kill -0 $XEPHYR_PID 2>/dev/null; do
            # Copy from host clipboard to Xephyr clipboard (if changed)
            HOST_CLIPBOARD=$(DISPLAY=":0" ${pkgs.xclip}/bin/xclip -o -selection clipboard 2>/dev/null || echo "")
            if [ -n "$HOST_CLIPBOARD" ] && [ "$HOST_CLIPBOARD" != "$LAST_HOST_CLIPBOARD" ]; then
              echo "$HOST_CLIPBOARD" | DISPLAY="$XEPHYR_DISPLAY" ${pkgs.xclip}/bin/xclip -i -selection clipboard 2>/dev/null || true
              echo "$HOST_CLIPBOARD" | DISPLAY="$XEPHYR_DISPLAY" ${pkgs.xclip}/bin/xclip -i -selection primary 2>/dev/null || true
              LAST_HOST_CLIPBOARD="$HOST_CLIPBOARD"
            fi
            
            # Copy from Xephyr clipboard to host clipboard (if changed)
            XEPHYR_CLIPBOARD=$(DISPLAY="$XEPHYR_DISPLAY" ${pkgs.xclip}/bin/xclip -o -selection clipboard 2>/dev/null || echo "")
            if [ -n "$XEPHYR_CLIPBOARD" ] && [ "$XEPHYR_CLIPBOARD" != "$LAST_XEPHYR_CLIPBOARD" ] && [ "$XEPHYR_CLIPBOARD" != "$HOST_CLIPBOARD" ]; then
              echo "$XEPHYR_CLIPBOARD" | DISPLAY=":0" ${pkgs.xclip}/bin/xclip -i -selection clipboard 2>/dev/null || true
              LAST_XEPHYR_CLIPBOARD="$XEPHYR_CLIPBOARD"
            fi
            
            # Also check primary selection (for middle-click paste)
            XEPHYR_PRIMARY=$(DISPLAY="$XEPHYR_DISPLAY" ${pkgs.xclip}/bin/xclip -o -selection primary 2>/dev/null || echo "")
            if [ -n "$XEPHYR_PRIMARY" ] && [ "$XEPHYR_PRIMARY" != "$LAST_XEPHYR_CLIPBOARD" ] && [ "$XEPHYR_PRIMARY" != "$HOST_CLIPBOARD" ]; then
              echo "$XEPHYR_PRIMARY" | DISPLAY=":0" ${pkgs.xclip}/bin/xclip -i -selection clipboard 2>/dev/null || true
              LAST_XEPHYR_CLIPBOARD="$XEPHYR_PRIMARY"
            fi
            
            sleep 0.5
          done
        ) &
        CLIPBOARD_PID=$!

        # Start i3 with logging enabled
        echo "=== i3 started at $(date) ===" >> "$I3_LOG_FILE"
        DISPLAY="$XEPHYR_DISPLAY" WAYLAND_DISPLAY="" ${pkgs.i3}/bin/i3 >> "$I3_LOG_FILE" 2>&1 &
        I3_PID=$!

        # Wait a bit for i3 to start
        sleep 2

        # Disable power management features that could kill Xephyr
        DISPLAY="$XEPHYR_DISPLAY" ${pkgs.xorg.xset}/bin/xset -dpms 2>/dev/null || true
        DISPLAY="$XEPHYR_DISPLAY" ${pkgs.xorg.xset}/bin/xset s off 2>/dev/null || true
        DISPLAY="$XEPHYR_DISPLAY" ${pkgs.xorg.xset}/bin/xset s noblank 2>/dev/null || true

        # Create a PID file for systemd service to track
        PIDFILE="/tmp/xephyr-$DISPLAY_NUM.pid"
        echo $XEPHYR_PID > "$PIDFILE"
        echo "Created PID file: $PIDFILE"

        # Set up auto-refresh and connection monitoring if enabled
        if [ "$AUTO_REFRESH" = true ]; then
            # Enhanced background process: monitors connection, auto-refresh, and keeps session alive
            (
                RECOVERY_ATTEMPTS=0
                MAX_RECOVERY_ATTEMPTS=10

                while kill -0 $XEPHYR_PID 2>/dev/null; do
                    sleep 5

                    # Keep-alive: Check if i3 is still running, restart if needed
                    if ! ${pkgs.procps}/bin/pgrep -f "i3.*$XEPHYR_DISPLAY" >/dev/null; then
                        echo "WARNING: i3 process died at $(date), restarting on $XEPHYR_DISPLAY..."
                        echo "=== i3 crashed and restarting at $(date) ===" >> "$I3_LOG_FILE"

                        # Give a moment for cleanup
                        sleep 1

                        # Restart i3 with logging and proper fontconfig environment
                        DISPLAY="$XEPHYR_DISPLAY" WAYLAND_DISPLAY="" \
                        FONTCONFIG_FILE="${pkgs.fontconfig.out}/etc/fonts/fonts.conf" \
                        FONTCONFIG_PATH="${pkgs.fontconfig.out}/etc/fonts" \
                        ${pkgs.i3}/bin/i3 >> "$I3_LOG_FILE" 2>&1 &
                        I3_PID=$!
                        sleep 2

                        # Check if restart was successful
                        if ${pkgs.procps}/bin/pgrep -f "i3.*$XEPHYR_DISPLAY" >/dev/null; then
                            echo "i3 restarted successfully"
                        else
                            echo "ERROR: i3 failed to restart - check log: $I3_LOG_FILE"
                        fi
                    fi

                    # Check if we can still communicate with X server
                    if ! DISPLAY="$XEPHYR_DISPLAY" ${pkgs.xorg.xrandr}/bin/xrandr -q >/dev/null 2>&1; then
                        echo "X11 connection lost (attempt $((RECOVERY_ATTEMPTS+1)))/$MAX_RECOVERY_ATTEMPTS, checking WSLg status..."

                        # Check if WSLg sockets still exist
                        if [ ! -S "/tmp/.X11-unix/X0" ] && [ ! -S "/tmp/.X11-unix/X1" ]; then
                            echo "FATAL: WSLg X11 server crashed. Xephyr cannot continue."
                            echo "Run 'wsl --shutdown' from Windows CMD, then restart WSL"
                            echo "Or try: systemctl --user restart xephyr-i3.service"
                            RECOVERY_ATTEMPTS=$((RECOVERY_ATTEMPTS+1))

                            if [ $RECOVERY_ATTEMPTS -ge $MAX_RECOVERY_ATTEMPTS ]; then
                                echo "Max recovery attempts reached. Giving up."
                                kill $XEPHYR_PID 2>/dev/null || true
                                exit 1
                            fi

                            # Wait longer for WSLg to recover
                            sleep 10
                            continue
                        fi

                        echo "WSLg sockets exist, attempting Xephyr recovery..."
                        # Wait a moment for potential reconnection
                        sleep 3

                        # Try to re-establish connection by reapplying settings
                        if DISPLAY="$XEPHYR_DISPLAY" ${pkgs.xorg.xset}/bin/xset -dpms 2>/dev/null; then
                            DISPLAY="$XEPHYR_DISPLAY" ${pkgs.xorg.xset}/bin/xset s off 2>/dev/null || true
                            DISPLAY="$XEPHYR_DISPLAY" ${pkgs.xorg.xset}/bin/xset s noblank 2>/dev/null || true
                            echo "Recovery successful!"
                            RECOVERY_ATTEMPTS=0
                        else
                            echo "Recovery attempt failed, will retry..."
                            RECOVERY_ATTEMPTS=$((RECOVERY_ATTEMPTS+1))
                        fi
                    else
                        # Connection is healthy, reset recovery counter
                        RECOVERY_ATTEMPTS=0
                    fi

                    # Refresh the display to fix canvas expansion issues
                    DISPLAY="$XEPHYR_DISPLAY" ${pkgs.xorg.xrandr}/bin/xrandr -q >/dev/null 2>&1 || true
                done

                # Cleanup PID file when Xephyr exits
                rm -f "$PIDFILE"
            ) &
            REFRESH_PID=$!
        fi

        # Focus the Xephyr window by starting a simple application
        DISPLAY="$XEPHYR_DISPLAY" ${pkgs.xterm}/bin/xterm -fa "JetBrains Mono" -fs 9 -e "echo 'i3 workspace ready. DPI: $DPI | Use Alt+Enter for terminal, Alt+d for dmenu, Alt+p for rofi | Alt+Shift+F5 to refresh display'; sleep 3" &

        # Function to cleanup on exit
        cleanup() {
            echo "Cleaning up..."
            [ -n "$REFRESH_PID" ] && kill "$REFRESH_PID" 2>/dev/null
            [ -n "$CLIPBOARD_PID" ] && kill "$CLIPBOARD_PID" 2>/dev/null
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
      # Background launcher for running startx without blocking terminal
      (writeShellScriptBin "startx-bg" ''
        #!/usr/bin/env bash
        echo "Starting i3-xephyr in background..."
        # Pass all arguments to startx
        nohup startx "$@" >/dev/null 2>&1 &
        PID=$!
        echo "i3-xephyr started in background (PID: $PID)"
        echo "Arguments passed: $*"
        echo "Xephyr window should appear shortly."
        echo "Use 'pkill -f Xephyr' to stop if needed."
      '')

      # Systemd service control wrapper
      (writeShellScriptBin "xephyr-service" ''
        #!/usr/bin/env bash

        case "''${1:-status}" in
          start)
            echo "Starting Xephyr i3 service..."
            systemctl --user start xephyr-i3.service
            ;; 
          stop)
            echo "Stopping Xephyr i3 service..."
            systemctl --user stop xephyr-i3.service
            ;; 
          restart)
            echo "Restarting Xephyr i3 service..."
            systemctl --user restart xephyr-i3.service
            ;; 
          status)
            systemctl --user status xephyr-i3.service
            ;; 
          enable)
            echo "Enabling Xephyr i3 service to start on login..."
            systemctl --user enable xephyr-i3.service
            echo "Service will auto-start on next login"
            ;; 
          disable)
            echo "Disabling Xephyr i3 service auto-start..."
            systemctl --user disable xephyr-i3.service
            ;; 
          logs)
            journalctl --user -u xephyr-i3.service -f
            ;; 
          *)
            echo "Usage: xephyr-service {start|stop|restart|status|enable|disable|logs}"
            echo ""
            echo "Commands:"
            echo "  start    - Start the Xephyr i3 session"
            echo "  stop     - Stop the Xephyr i3 session"
            echo "  restart  - Restart the Xephyr i3 session"
            echo "  status   - Show service status"
            echo "  enable   - Enable auto-start on login"
            echo "  disable  - Disable auto-start"
            echo "  logs     - Follow service logs"
            exit 1
            ;;
        esac
      '')

      # i3 log viewer for debugging crashes
      (writeShellScriptBin "i3-logs" ''
        #!/usr/bin/env bash

        I3_LOG_DIR="$HOME/.local/share/i3/logs"

        if [ ! -d "$I3_LOG_DIR" ]; then
            echo "No i3 logs found at $I3_LOG_DIR"
            exit 1
        fi

        case "''${1:-tail}" in
          tail|follow)
            LATEST_LOG=$(ls -t "$I3_LOG_DIR"/i3-*.log 2>/dev/null | head -1)
            if [ -z "$LATEST_LOG" ]; then
                echo "No i3 log files found"
                exit 1
            fi
            echo "Following: $LATEST_LOG"
            tail -f "$LATEST_LOG"
            ;;
          latest|cat)
            LATEST_LOG=$(ls -t "$I3_LOG_DIR"/i3-*.log 2>/dev/null | head -1)
            if [ -z "$LATEST_LOG" ]; then
                echo "No i3 log files found"
                exit 1
            fi
            echo "=== $LATEST_LOG ==="
            cat "$LATEST_LOG"
            ;;
          list|ls)
            echo "Available i3 logs:"
            ls -lth "$I3_LOG_DIR"/i3-*.log 2>/dev/null || echo "No log files found"
            ;;
          clean)
            echo "Cleaning old i3 logs (keeping last 10)..."
            ls -t "$I3_LOG_DIR"/i3-*.log 2>/dev/null | tail -n +11 | xargs -r rm -v
            echo "Done"
            ;;
          *)
            echo "Usage: i3-logs {tail|latest|list|clean}"
            echo ""
            echo "Commands:"
            echo "  tail     - Follow the latest i3 log file (default)"
            echo "  latest   - Show the latest i3 log file"
            echo "  list     - List all i3 log files"
            echo "  clean    - Remove old log files (keep last 10)"
            exit 1
            ;;
        esac
      '')
    ];

    # Systemd user service for persistent Xephyr/i3 session
    systemd.user.services.xephyr-i3 = {
      Unit = {
        Description = "Xephyr i3 Window Manager Session";
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Service = {
        Type = "simple";
        ExecStart = "${pkgs.bash}/bin/bash -c 'exec startx'";
        Restart = "on-failure";
        RestartSec = "5s";

        # Important: Don't kill the service when the shell exits
        KillMode = "control-group";

        # Environment variables
        Environment = [
          "DISPLAY=:0"
          "XDG_CONFIG_HOME=%h/.config"
          "FONTCONFIG_FILE=${pkgs.fontconfig.out}/etc/fonts/fonts.conf"
          "FONTCONFIG_PATH=${pkgs.fontconfig.out}/etc/fonts"
          "PATH=%h/.nix-profile/bin:${pkgs.lib.makeBinPath (with pkgs; [
            xorg.xorgserver
            i3
            xterm
            procps
            xorg.xrandr
            xorg.xset
            coreutils
            bash
          ])}"
        ];
      };

      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };
}
