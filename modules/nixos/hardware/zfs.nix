{
  config,
  pkgs,
  lib,
  ...
}:
{

  options = {
    zfs.enable = lib.mkEnableOption "ZFS file system.";
  };

  config = lib.mkIf (config.server && config.zfs.enable) {

    # Only use compatible Linux kernel, since ZFS can be behind
    boot.kernelPackages = pkgs.linuxPackages; # Defaults to latest LTS
    boot.kernelParams = [ "nohibernate" ];
    boot.supportedFilesystems = [ "zfs" ];
  };
}
