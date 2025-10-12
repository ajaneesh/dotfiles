{ ... }:

{
  imports = [
    ../modules/common/applications/xephyr.nix
    ./hm-common.nix
  ];

  # Enable i3 with Xephyr for Crostini
  xephyr.enable = true;
}