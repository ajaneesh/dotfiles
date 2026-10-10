{ ... }:

{
  imports = [
    ../modules/common/applications/i3.nix
    ../modules/common/applications/screenshots.nix
    ../modules/common/applications/native-x-session.nix
    ../modules/common/applications/network-manager.nix
    ../modules/common/applications/vpn-cli.nix
    ./hm-common.nix
  ];

  # Native i3 on apt-based Debian (home machine).
  i3.enable = true;
  screenshots.enable = true;

  # Run nm-applet as the NetworkManager secret agent so VPN/Wi-Fi passwords can
  # be stored (encrypted) in gnome-keyring and supplied automatically - the
  # piece a non-Plasma i3 session otherwise lacks. Manage profiles with
  # nm-connection-editor, "store for this user".
  networkManager.enable = true;

  # Convenience nmcli wrappers (vpn-up/vpn-down/vpn-status). With the secret
  # agent above running, vpn-up connects using the gnome-keyring-stored
  # password (or prompts via --ask if none is saved).
  vpnCli.enable = true;

  # Native host: bind Super/Win+L to lock + switch user (LightDM greeter), so family
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
