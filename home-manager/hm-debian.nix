{ ... }:

{
  imports = [
    ../modules/common/applications/i3.nix
    ../modules/common/applications/screenshots.nix
    ../modules/common/applications/native-x-session.nix
    ./hm-common.nix
  ];

  # Native i3 on apt-based Debian (home machine).
  i3.enable = true;
  screenshots.enable = true;

  # Native host: bind Super/Win+L to lock + switch user (SDDM greeter), so family
  # members can log into their own accounts. (On WSL/Crostini Win+L is left to
  # the host OS instead.)
  i3.superLock = true;

  # Denser default sizing (this is a HiDPI panel). One knob, relative to the
  # display's real DPI; override at runtime with `display-scale set N`.
  display.scale = 0.75;

  # Native X bootstrap: .xinitrc, startx service, and the `x11-setup` helper
  # (run `x11-setup` once: `apt install xorg xinit i3lock zsh`, PAM, register i3 session).
  nativeXSession.enable = true;
}
