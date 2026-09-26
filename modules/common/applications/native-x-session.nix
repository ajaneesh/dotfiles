{ config, pkgs, lib, ... }:

# Native X11 session bootstrap for apt-based, non-NixOS hosts (Debian, Ubuntu).
#
# Lets the Nix/home-manager-managed i3 be launched two ways on a distro where
# Nix does NOT manage the system:
#   1. From a display manager (SDDM): the `x11-setup` helper installs a session
#      .desktop into /usr/local/share/xsessions pointing at the `i3-session`
#      launcher below, so the DM lists "i3 (home-manager)" and runs the *Nix*
#      i3 (not an apt one).
#   2. Via `startx`: an `.xinitrc` is provided; the auto-start service is left
#      installed but disabled by default so it does not fight the DM.
#
# Reproducibility note: this is home-manager *standalone* on Debian, so HM can
# only write under $HOME. The one unavoidable root-owned artifact (the system
# xsessions .desktop) is created by the repo-defined `x11-setup` script rather
# than by hand, keeping the whole setup rebuildable from this config.
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
    home.packages = [
      # Session launcher the display manager (SDDM) invokes to start the
      # home-manager-managed i3 with the correct Nix environment. Installed at a
      # stable path (~/.nix-profile/bin/i3-session) so the system .desktop file
      # created by x11-setup never points at a garbage-collectable /nix/store
      # path. Mirrors the PATH/XDG setup in the .xinitrc below.
      (pkgs.writeShellScriptBin "i3-session" ''
        export PATH="$HOME/.nix-profile/bin:/nix/var/nix/profiles/default/bin:$PATH"
        export XDG_DATA_DIRS="$HOME/.nix-profile/share:''${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
        exec ${pkgs.i3}/bin/i3
      '')

      # One-time system setup. Run `x11-setup` once per machine. Idempotent:
      # safe to re-run after a config change (e.g. to refresh the session file).
      (pkgs.writeShellScriptBin "x11-setup" ''
        echo "Setting up system dependencies for a native i3 X session..."
        echo ""
        echo "This will (via apt / sudo):"
        echo "  - install xorg, xinit (X11 server) and i3lock (PAM screen lock)"
        echo "  - install zsh from apt and make /usr/bin/zsh your login shell"
        echo "    (so a broken Nix profile can never lock you out of a shell)"
        echo "  - register an 'i3 (home-manager)' session with the display manager"
        echo "  - remove the apt-installed i3 (so its duplicate session entry,"
        echo "    which launches the wrong binary, goes away)"
        echo ""
        read -p "Continue? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
          sudo apt install -y xorg xinit i3lock zsh

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

          # Register the home-manager i3 session with the display manager.
          # SDDM (like most DMs) only scans /usr/local/share/xsessions and
          # /usr/share/xsessions as root -- it never reads ~/.local/share/
          # xsessions, which is why the HM-written entry never appeared. We
          # install into /usr/local/share/xsessions (the local-admin dir) and
          # point Exec at the stable i3-session launcher above.
          echo "Registering the home-manager i3 session with the display manager..."
          sudo install -d /usr/local/share/xsessions
          sudo tee /usr/local/share/xsessions/i3-hm.desktop > /dev/null <<EOF
[Desktop Entry]
Name=i3 (home-manager)
Comment=i3 window manager launched from the Nix/home-manager profile
Exec=${config.home.homeDirectory}/.nix-profile/bin/i3-session
Type=Application
DesktopNames=i3
EOF

          # Drop the apt i3: its /usr/share/xsessions/*.desktop entries run
          # /usr/bin/i3 (the apt binary), shadowing the Nix one. Removing it
          # leaves "i3 (home-manager)" as the session to pick at login.
          if dpkg -s i3 >/dev/null 2>&1 || dpkg -s i3-wm >/dev/null 2>&1; then
            echo "Removing the apt-installed i3 (i3, i3-wm)..."
            sudo apt remove -y i3 i3-wm || true
          fi

          # Make the apt zsh the login shell. home-manager still writes ~/.zshrc
          # (which any zsh reads), but the SHELL binary is the distro's, so a
          # broken/rolled-back Nix profile can't leave you without a usable login
          # shell. chsh requires the shell to be listed in /etc/shells.
          if [ -x /usr/bin/zsh ]; then
            grep -qx /usr/bin/zsh /etc/shells || echo /usr/bin/zsh | sudo tee -a /etc/shells >/dev/null
            if [ "$(getent passwd "$USER" | cut -d: -f7)" != "/usr/bin/zsh" ]; then
              echo "Setting /usr/bin/zsh as your login shell..."
              sudo chsh -s /usr/bin/zsh "$USER"
            fi
          fi

          echo ""
          echo "Setup complete!"
          echo "  - Log out, then pick 'i3 (home-manager)' at the SDDM session menu."
          echo "  - Alt+Shift+Z locks the screen."
          echo "  - Your login shell is now /usr/bin/zsh (config still from home-manager)."
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

    # Manual `startx` fallback unit. Deliberately NOT WantedBy any target: we
    # now log in through the display manager (SDDM), and auto-starting startx
    # here would race/fight the DM-managed X server. Start it by hand with
    # `systemctl --user start startx` only if you want the old startx flow.
    systemd.user.services.startx = {
      Unit = {
        Description = "Start X11 with i3 window manager (manual startx fallback)";
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
    };
  };
}
