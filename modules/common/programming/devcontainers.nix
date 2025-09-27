{ config, pkgs, lib, ... }:

{
  options.devcontainers.enable = lib.mkEnableOption "Enable devcontainers CLI";

  config = lib.mkIf config.devcontainers.enable {
    home.packages = with pkgs; [
      devcontainer
    ];
  };
}
