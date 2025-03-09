{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ./integration.nix
    ./i3.nix
  ];

  config = lib.mkIf (pkgs.stdenv.isLinux && config.wsl.enable) {
    # Systemd doesn't work in WSL without native systemd
    services.geoclue2.enable = lib.mkForce false;
    location = {
      provider = lib.mkForce "manual";
    };
    services.localtimed.enable = lib.mkForce false;

    # Clipboard sharing with Windows and i3 launcher script
    home-manager.users.${config.user}.home.packages = with pkgs; [
      # win32yank  # Clipboard integration with Windows
      
      # Create convenience script for launching i3 in WSLg
      (writeShellScriptBin "launch-i3" ''
        #!/usr/bin/env bash

        # Check if WSLg is running (DISPLAY should be set)
        if [ -z "$DISPLAY" ]; then
        echo "DISPLAY is not set. Are you running WSLg?"
        exit 1
        fi

        # Kill any existing i3 instances
        if pgrep -x "i3" > /dev/null; then
        echo "Killing existing i3 instance..."
        pkill i3
        sleep 1
        fi

        # Set up environment for i3
        export XDG_CURRENT_DESKTOP=i3
        export DESKTOP_SESSION=i3

        # Launch i3 with a log file for debugging
        echo "Starting i3..."
        i3 -V > ~/i3-wsl.log 2>&1 &

        # Wait for i3 to initialize
        sleep 2

        # Launch a terminal in workspace 1
        i3-msg 'workspace 1; exec wezterm'

        echo "i3 started successfully!"
      '')
    ];
    
    # Configure autostart for i3
    #   home-manager.users.${config.user}.xdg.configFile."autostart/i3-wsl.desktop" = {
    #     text = ''
    #       [Desktop Entry]
    #       Type=Application
    #       Name=i3 Window Manager (WSL)
    #       Exec=launch-i3
    #       Terminal=false
    #       Categories=System;
    #       Comment=Start i3 Window Manager in WSL
    #     '';
    #   };
  };
}
