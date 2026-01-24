{ pkgs, ... }:

{
  imports = [
    ../modules/common/applications/xephyr.nix
    ./hm-common.nix
  ];

  # Enable i3 with Xephyr for Crostini
  xephyr.enable = true;

  # Common applications for all machines
  home.packages = with pkgs; [
    hypnotix
    vlc
    (pkgs.writeShellScriptBin "kodi" ''
      exec ${pkgs.nixgl.nixGLIntel}/bin/nixGLIntel ${pkgs.kodi}/bin/kodi "$@"
    '')
  ];
}
