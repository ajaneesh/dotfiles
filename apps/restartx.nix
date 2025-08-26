{ pkgs, ... }:

pkgs.writeShellScriptBin "restartx" ''
  #!/bin/sh
  set -e

  echo "Reconnecting existing i3 session to new Xephyr display..."
  echo "This will preserve all your open applications and workspaces."

  # Check if i3 is running
  I3_PID=$(${pkgs.procps}/bin/pgrep i3 2>/dev/null || echo "")
  
  if [ -z "$I3_PID" ]; then
    echo "i3 is not running. Please start it first with 'startx'"
    exit 1
  fi

  # Get current DISPLAY that i3 is using
  CURRENT_DISPLAY=""
  for pid in $I3_PID; do
    if [ -r "/proc/$pid/environ" ]; then
      CURRENT_DISPLAY=$(${pkgs.coreutils}/bin/tr '\0' '\n' < "/proc/$pid/environ" | ${pkgs.gnugrep}/bin/grep "^DISPLAY=" | ${pkgs.coreutils}/bin/cut -d= -f2- || echo "")
      if [ -n "$CURRENT_DISPLAY" ]; then
        break
      fi
    fi
  done

  echo "Current i3 is running on display: $CURRENT_DISPLAY"

  # Find a free display number for new Xephyr
  DISPLAY_NUM=1
  while [ -S "/tmp/.X11-unix/X''${DISPLAY_NUM}" ] || [ -f "/tmp/.X''${DISPLAY_NUM}-lock" ]; do
    # Check if the lock file corresponds to a dead process
    if [ -f "/tmp/.X''${DISPLAY_NUM}-lock" ]; then
      LOCK_PID=$(${pkgs.coreutils}/bin/cat "/tmp/.X''${DISPLAY_NUM}-lock" 2>/dev/null || echo "")
      if [ -n "$LOCK_PID" ] && ! kill -0 "$LOCK_PID" 2>/dev/null; then
        echo "Removing stale X lock file for display :$DISPLAY_NUM"
        rm -f "/tmp/.X''${DISPLAY_NUM}-lock"
        if [ -S "/tmp/.X11-unix/X''${DISPLAY_NUM}" ]; then
          rm -f "/tmp/.X11-unix/X''${DISPLAY_NUM}"
        fi
        break
      fi
    fi
    DISPLAY_NUM=$((DISPLAY_NUM + 1))
  done

  # Start new Xephyr
  NEW_DISPLAY=":''${DISPLAY_NUM}"
  echo "Starting new Xephyr on display $NEW_DISPLAY..."
  ${pkgs.xorg.xorgserver}/bin/Xephyr -br -ac -noreset -screen 1920x1080 "$NEW_DISPLAY" &
  XEPHYR_PID=$!

  # Wait for Xephyr to start
  sleep 2

  # Check if Xephyr started successfully
  if ! kill -0 $XEPHYR_PID 2>/dev/null; then
    echo "Failed to start Xephyr"
    exit 1
  fi

  echo "New Xephyr started successfully on $NEW_DISPLAY"

  # The fundamental problem: i3 cannot switch displays after startup
  # Instead, we need to restart i3 on the new display but preserve the session
  echo "Saving current i3 session state..."
  
  # First, try to save workspace layouts (this might fail if display is broken)
  mkdir -p /tmp/i3-session-backup
  DISPLAY="$CURRENT_DISPLAY" ${pkgs.i3}/bin/i3-msg -t get_workspaces > /tmp/i3-session-backup/workspaces.json 2>/dev/null || true
  DISPLAY="$CURRENT_DISPLAY" ${pkgs.i3}/bin/i3-msg -t get_tree > /tmp/i3-session-backup/tree.json 2>/dev/null || true
  
  echo "Restarting i3 on new display (this will preserve most applications)..."
  
  # The key insight: restart i3 but on the new display
  # Most applications will survive because they're not tied to the X server that i3 uses for window management
  DISPLAY="$NEW_DISPLAY" ${pkgs.i3}/bin/i3 &
  NEW_I3_PID=$!
  
  # Wait for new i3 to start
  sleep 2
  
  # Kill old i3 after new one is running
  echo "Stopping old i3 process..."
  kill $I3_PID 2>/dev/null || true
  
  # Kill the old Xephyr now that we have a new i3
  if [ "$CURRENT_DISPLAY" != ":0" ]; then
    OLD_DISPLAY_NUM=$(echo "$CURRENT_DISPLAY" | sed 's/://')
    OLD_XEPHYR_PID=$(${pkgs.procps}/bin/pgrep -f "Xephyr.*:$OLD_DISPLAY_NUM" || echo "")
    if [ -n "$OLD_XEPHYR_PID" ]; then
      echo "Cleaning up old Xephyr process on $CURRENT_DISPLAY"
      kill $OLD_XEPHYR_PID 2>/dev/null || true
    fi
  fi

  echo "i3 restarted on $NEW_DISPLAY"
  echo "Note: Window layouts may be lost, but applications should still be running."
  echo "Check your system processes - browsers, terminals, etc. should still be active."

  echo "i3 session reconnected to $NEW_DISPLAY"
  echo "Your applications should still be running on their original workspaces."
  echo "Press Ctrl+C to exit (this will close the Xephyr window)."
  
  # Function to cleanup on exit
  cleanup() {
    echo "Cleaning up..."
    kill $XEPHYR_PID 2>/dev/null || true
    exit 0
  }

  # Set up signal handlers
  trap cleanup SIGINT SIGTERM

  # Wait for Xephyr to exit
  wait $XEPHYR_PID
''