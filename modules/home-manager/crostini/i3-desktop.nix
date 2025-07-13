{ config, pkgs, ... }:

{
  # Desktop entry for launching i3 in Xephyr
  xdg.desktopEntries.i3-xephyr = {
    name = "i3 Window Manager (Nested)";
    comment = "Launch i3 in a nested X server using Xephyr";
    exec = "${config.home.homeDirectory}/.local/bin/i3-xephyr";
    icon = "i3";
    terminal = false;
    categories = [ "Utility" ];
    startupNotify = true;
  };
}