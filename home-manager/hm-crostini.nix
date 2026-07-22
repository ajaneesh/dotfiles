{ pkgs, ... }:

{
  imports = [
    ../modules/common/applications/xephyr.nix
    ./hm-common.nix
  ];

  # Enable i3 with Xephyr for Crostini
  xephyr.enable = true;

  # Crostini-specific media apps, wrapped with nixGL for GPU access
  home.packages = with pkgs; [
    (pkgs.writeShellScriptBin "hypnotix" ''
      exec ${pkgs.nixgl.nixGLIntel}/bin/nixGLIntel ${pkgs.hypnotix}/bin/hypnotix "$@"
    '')
    (pkgs.writeShellScriptBin "vlc" ''
      exec ${pkgs.vlc}/bin/vlc --avcodec-hw=none --vout=x11 "$@"
    '')
    (let
      kodi-with-addons = pkgs.kodi.withPackages (p: with p; [
        pvr-iptvsimple
      ]);
    in pkgs.writeShellScriptBin "kodi" ''
      exec ${pkgs.nixgl.nixGLIntel}/bin/nixGLIntel ${kodi-with-addons}/bin/kodi "$@"
    '')
  ];
}
