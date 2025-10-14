{ config, pkgs, lib, ... }:

{
  options = {
    screenshots.enable = lib.mkEnableOption "screenshot tools";
  };

  config = lib.mkIf config.screenshots.enable {
    home.packages = with pkgs; [
      scrot             # Screenshot utility
      xdotool           # Window information for screenshots
      xclip             # Clipboard support for screenshots
      libnotify         # Notifications for screenshot confirmation
      imagemagick       # For clipboard support

      # Screenshot helper scripts
      (writeShellScriptBin "screenshot" ''
        #!/usr/bin/env bash
        # Full screen screenshot
        SCREENSHOT_DIR="$HOME/Pictures/Screenshots"
        mkdir -p "$SCREENSHOT_DIR"
        FILENAME="$SCREENSHOT_DIR/screenshot-$(date +%Y%m%d-%H%M%S).png"

        ${scrot}/bin/scrot "$FILENAME"
        ${libnotify}/bin/notify-send "Screenshot" "Saved to $FILENAME"
        echo "$FILENAME"
      '')

      (writeShellScriptBin "screenshot-select" ''
        #!/usr/bin/env bash
        # Selection screenshot
        SCREENSHOT_DIR="$HOME/Pictures/Screenshots"
        mkdir -p "$SCREENSHOT_DIR"
        FILENAME="$SCREENSHOT_DIR/screenshot-$(date +%Y%m%d-%H%M%S).png"

        ${scrot}/bin/scrot -s "$FILENAME" && \
          ${libnotify}/bin/notify-send "Screenshot" "Selection saved to $FILENAME" || \
          ${libnotify}/bin/notify-send "Screenshot" "Cancelled"
      '')

      (writeShellScriptBin "screenshot-window" ''
        #!/usr/bin/env bash
        # Active window screenshot
        SCREENSHOT_DIR="$HOME/Pictures/Screenshots"
        mkdir -p "$SCREENSHOT_DIR"
        FILENAME="$SCREENSHOT_DIR/screenshot-$(date +%Y%m%d-%H%M%S).png"

        ${scrot}/bin/scrot -u "$FILENAME"
        ${libnotify}/bin/notify-send "Screenshot" "Window saved to $FILENAME"
        echo "$FILENAME"
      '')

      (writeShellScriptBin "screenshot-clip" ''
        #!/usr/bin/env bash
        # Screenshot selection to clipboard
        SCREENSHOT_DIR="$HOME/Pictures/Screenshots"
        mkdir -p "$SCREENSHOT_DIR"
        TEMP_FILE="$SCREENSHOT_DIR/clipboard-$(date +%Y%m%d-%H%M%S).png"

        if ${scrot}/bin/scrot -s "$TEMP_FILE" 2>/dev/null; then
          # Copy to clipboard - keep file for clipboard persistence
          ${xclip}/bin/xclip -selection clipboard -t image/png -i "$TEMP_FILE"
          ${libnotify}/bin/notify-send "Screenshot" "Copied to clipboard"

          # Clean up old clipboard screenshots (older than 1 hour)
          find "$SCREENSHOT_DIR" -name "clipboard-*.png" -type f -mmin +60 -delete 2>/dev/null || true
        else
          ${libnotify}/bin/notify-send "Screenshot" "Cancelled"
        fi
      '')
    ];
  };
}
