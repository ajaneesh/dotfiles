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
          all-the-icons
          aggressive-indent
          treemacs-all-the-icons
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
          consult-project-extra
	        wgrep
	        orderless
	        cape
	        corfu
	        clojure-mode
          clj-refactor
	        cider
	        flycheck-clj-kondo
	        json-mode
	        yafolding
	        nix-mode
          magit
          transient
          magit-section
          treemacs
          yasnippet
          yasnippet-snippets
          yasnippet-capf
          clojure-snippets
          paredit
          rainbow-delimiters
	      ];
      };

    };
  };
}
