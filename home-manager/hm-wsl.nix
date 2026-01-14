{ ... }:

{
  imports = [
    ../modules/common/applications/xephyr.nix
    ../modules/common/applications/screenshots.nix
    ./hm-common.nix
  ];

  # Enable i3 with Xephyr for WSL
  xephyr.enable = true;

  # Enable screenshot tools
  screenshots.enable = true;
}