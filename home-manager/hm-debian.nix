{ pkgs, ... }:

{
  imports = [
    ../modules/common/applications/i3.nix
    ./hm-common.nix
  ];

  # Enable i3 natively for Debian
  i3.enable = true;

  # Required Debian system packages (install via apt):
  # sudo apt install xorg xinit

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
