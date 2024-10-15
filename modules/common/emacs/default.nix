{
  config,
  pkgs,
  lib,
  ...
}:
{

  options.emacs.enable = lib.mkEnableOption "emacs and related packages";

  config = lib.mkIf config.emacs.enable {

    home-manager.users.${config.user} = {

      home.packages = with pkgs; [
        emacs
        emacsPackages.org
        emacsPackages.swiper
        emacsPackages.vertico
        emacsPackages.magit
        emacsPackages.evil
        emacsPackages.consult
        emacsPackages.marginalia
      ];

    };
  };
}