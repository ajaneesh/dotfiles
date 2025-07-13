{ config, pkgs, ... }:

{
  # Enable the common i3 configuration
  i3.enable = true;

  # Crostini-specific additions for Xephyr support
  home.packages = with pkgs; [
    xorg.xorgserver  # Provides Xephyr
    rofi             # Add rofi for launcher
  ];

  # Create the launcher script
  home.file.".local/bin/i3-xephyr" = {
    source = ./i3-xephyr.sh;
    executable = true;
  };
}
