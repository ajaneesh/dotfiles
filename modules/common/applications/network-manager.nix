{ config, pkgs, lib, ... }:

{
  options = {
    networkManager.enable = lib.mkEnableOption "NetworkManager secret agent (nm-applet) for i3";
  };

  config = lib.mkIf config.networkManager.enable {
    # In an i3 (non-Plasma) session nothing provides a NetworkManager *secret
    # agent*, so NM can neither save nor retrieve "agent-owned" connection
    # secrets - which is why editing a VPN in KDE System Settings here silently
    # loses the password (plasma-nm's agent, and its KWallet, only run under
    # Plasma; kwalletd isn't even unlocked in i3).
    #
    # Run the apt nm-applet instead: it registers as the session's NM secret
    # agent and stores/reads secrets via gnome-keyring - the Secret Service
    # that IS running here and is auto-unlocked at LightDM login by
    # pam_gnome_keyring. Result: secrets are encrypted (no plaintext keyfile),
    # entered once, and then supplied automatically whether you connect from
    # nm-applet's tray, the i3blocks VPN block, or `nmcli`/`vpn-up`.
    #
    # Manage profiles with nm-connection-editor (also apt) and set each
    # secret's storage to "Store the password only for this user" so it lands
    # in gnome-keyring. nm-applet/editor MUST be apt, not Nix, so they match the
    # apt NM daemon and apt OpenVPN GUI plugin (see native-x-session.nix); they
    # are installed by the `x11-setup` helper. This module only autostarts the
    # agent. Keyed off the home-manager i3 enable so it is a no-op on non-i3
    # profiles. Guarded so an i3 reload never spawns a second applet.
    xsession.windowManager.i3.config.startup = lib.mkIf config.xsession.windowManager.i3.enable [
      {
        command = "pgrep -x nm-applet >/dev/null || /usr/bin/nm-applet";
        always = true;
        notification = false;
      }
    ];
  };
}
