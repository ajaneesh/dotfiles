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
	    which-key
	    ligature
	    pyvenv
	    all-the-icons
	    evil
	    modus-themes
	    undo-tree
	    evil-collection
	    evil-surround
	    evil-commentary
	    evil-matchit
	    expand-region
	    lsp-pyright
	    vertico
	    marginalia
	    consult-lsp
	    wgrep
	    orderless
	    cape
	    corfu
	    clojure-mode
	    cider
	    flycheck-clj-kondo
	    json-mode
	    yafolding
	    nix-mode
        magit
        transient
        magit-section
	    ];
        };

    };
  };
}
