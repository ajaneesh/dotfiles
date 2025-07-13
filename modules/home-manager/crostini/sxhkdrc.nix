{ config, pkgs, ... }:

{
  xdg.configFile."sxhkd/sxhkdrc".source = pkgs.writeText "sxhkdrc" ''
    super + d
      ${pkgs.dmenu}/bin/dmenu_run

    super + Return
      ${pkgs.alacritty}/bin/alacritty
  '';
}
