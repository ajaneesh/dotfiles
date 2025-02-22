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

        programs.emacs = {
            enable = true;
	    extraPackages = epkgs: with epkgs; [
        magit
        transient
        magit-section
	    ];
        };

    };
  };
}
