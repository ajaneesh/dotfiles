{ pkgs, ... }:

{
  imports = [
    ../modules/common/applications/i3.nix
    ./hm-common.nix
  ];

  # Enable i3 natively for Debian
  i3.enable = true;

  # Required Debian system packages for reproducible setup:
  # Run this once to set up the system:
  #   sudo apt install xorg xinit i3lock
  #
  # Why i3lock via apt?
  # - i3lock needs setuid permissions to read /etc/shadow for password auth
  # - Nix packages can't have setuid on non-NixOS systems
  # - The overlay ensures we use the system's i3lock consistently

  # Setup script for Debian dependencies
  home.packages = with pkgs; [
    (writeShellScriptBin "debian-setup" ''
      echo "Setting up Debian system dependencies for i3..."
      echo ""
      echo "This will install:"
      echo "  - xorg, xinit (X11 server)"
      echo "  - i3lock (screen locker with PAM auth)"
      echo ""
      read -p "Continue? (y/n) " -n 1 -r
      echo
      if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo apt install -y xorg xinit i3lock

        # Ensure PAM config exists
        if [ ! -f /etc/pam.d/i3lock ]; then
          echo "Creating /etc/pam.d/i3lock..."
          sudo tee /etc/pam.d/i3lock > /dev/null <<'EOF'
# PAM configuration file for the i3lock screen locker
auth include common-auth
account include common-account
password include common-password
session include common-session
EOF
        fi

        echo ""
        echo "Setup complete! You can now use Alt+Shift+Z to lock your screen."
      fi
    '')
  ];

  # Create .xinitrc for startx
  home.file.".xinitrc".text = ''
    #!/bin/sh

    # Source system and user profiles
    if [ -d /etc/X11/xinit/xinitrc.d ]; then
      for f in /etc/X11/xinit/xinitrc.d/?*.sh; do
        [ -x "$f" ] && . "$f"
      done
      unset f
    fi

    # Ensure Nix packages are in PATH
    export PATH="$HOME/.nix-profile/bin:/nix/var/nix/profiles/default/bin:$PATH"
    export XDG_DATA_DIRS="$HOME/.nix-profile/share:''${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"

    # Start i3
    exec ${pkgs.i3}/bin/i3
  '';

  # Make .xinitrc executable
  home.file.".xinitrc".executable = true;

  # Systemd user service for auto-starting X11 on login (optional)
  systemd.user.services.startx = {
    Unit = {
      Description = "Start X11 with i3 window manager";
      After = [ "graphical-session-pre.target" ];
    };

    Service = {
      Type = "simple";
      ExecStart = "${pkgs.bash}/bin/bash -c 'exec startx'";
      Restart = "on-failure";
      RestartSec = "5s";
      Environment = [
        "PATH=${pkgs.lib.makeBinPath [ pkgs.coreutils pkgs.bash ]}:$HOME/.nix-profile/bin:/usr/bin"
      ];
    };

    Install = {
      WantedBy = [ "default.target" ];
    };
  };

}
