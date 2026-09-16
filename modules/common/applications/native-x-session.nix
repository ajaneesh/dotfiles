{ config, pkgs, lib, ... }:

# Native X11 session bootstrap for apt-based, non-NixOS hosts (Debian, Ubuntu).
#
# Provides the pieces that let `startx` bring up i3 on a distro where Nix does
# NOT manage the system: an `.xinitrc`, an optional login autostart service,
# and a one-time helper that installs the handful of system packages that must
# come from apt rather than Nix.
#
# Why apt (not Nix) for xorg/xinit/i3lock?
#   - i3lock needs the setuid bit to read /etc/shadow for PAM password auth.
#   - Nix packages can't be setuid on non-NixOS systems.
#   - So the distro's own xorg/xinit/i3lock give consistent, working auth.
#
# The i3 config itself (and the Alt+Shift+Z lock-screen binding) lives in
# i3.nix; this module only handles getting X up and the apt prerequisites in.

{
  options.nativeXSession.enable =
    lib.mkEnableOption "native X11 session (startx + i3) for apt-based non-NixOS hosts";

  config = lib.mkIf config.nativeXSession.enable {
    # One-time system dependency installer. Run `x11-setup` once per machine.
    home.packages = [
      (pkgs.writeShellScriptBin "x11-setup" ''
        echo "Setting up system dependencies for a native i3 X session..."
        echo ""
        echo "This will install (via apt):"
        echo "  - xorg, xinit (X11 server)"
        echo "  - i3lock (screen locker with PAM auth)"
        echo ""
        read -p "Continue? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
          sudo apt install -y xorg xinit i3lock

          # Ensure the PAM config exists so i3lock can authenticate.
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

    # .xinitrc for `startx`
    home.file.".xinitrc" = {
      executable = true;
      text = ''
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
    };

    # Optional: auto-start X11 with i3 on login.
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
  };
}
