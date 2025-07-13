{ config, pkgs, ... }:

{
  # i3 Window Manager Configuration

  xsession.enable = true;
  xsession.windowManager.i3 = {
    enable = true;
    config = {
      modifier = "Mod4"; # Use the Super key as the modifier
      bars = [
        {
          statusCommand = "${pkgs.i3status}/bin/i3status";
        }
      ];
      keybindings = {
        "Mod+d" = "exec ${pkgs.dmenu}/bin/dmenu_run";
        "Mod+Return" = "exec ${pkgs.alacritty}/bin/alacritty";
      };
    };
  };
}
