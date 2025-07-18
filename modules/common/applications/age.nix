# modules/common/applications/age.nix
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.age-manager;
in {
  options.age-manager = {
    enable = mkEnableOption "age secret management tools";
  };

  config = mkIf cfg.enable {
    home-manager.users.${config.user} = {
      imports = [ ../../home-manager/common/age.nix ];
    };
  };
}
