{ pkgs, ... }:

{
  home.packages = with pkgs; [
    (writeShellScriptBin "start-i3" ''
      #!/bin/sh
      # This script launches the i3 window manager with the default terminal.
      export DISPLAY=:0
      exec ${pkgs.wezterm}/bin/wezterm
    '')
  ];
}
