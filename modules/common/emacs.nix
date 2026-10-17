{ config, pkgs, lib, ... }:

let
  # emacs-tangle - regenerate ~/.emacs.d/init.el from init.org without opening
  # Emacs interactively. The literate config (init.org) is the source of truth;
  # its header-args already tangle to ~/.emacs.d/init.el, so a batch
  # org-babel-tangle reproduces exactly what `M-x org-babel-tangle` would.
  #
  # It tangles the init.org you edit in the dotfiles working tree (so the loop is
  # edit -> emacs-tangle -> restart Emacs, no rebuild). Source resolution, first
  # hit wins: a path given as $1, then $DOTFILES_DIR, then ~/dotfiles.
  emacs-tangle = pkgs.writeShellScriptBin "emacs-tangle" ''
    set -eu
    rel="modules/common/emacs/init.org"
    if [ "$#" -ge 1 ]; then
      src="$1"
    elif [ -n "''${DOTFILES_DIR:-}" ] && [ -f "$DOTFILES_DIR/$rel" ]; then
      src="$DOTFILES_DIR/$rel"
    else
      src="$HOME/dotfiles/$rel"
    fi

    if [ ! -f "$src" ]; then
      echo "emacs-tangle: init.org not found at: $src" >&2
      echo "  pass the path (emacs-tangle /path/to/init.org) or set DOTFILES_DIR" >&2
      exit 1
    fi

    echo "Tangling $src -> ~/.emacs.d/init.el ..."
    ${config.programs.emacs.finalPackage}/bin/emacs --batch -Q \
      --eval "(require 'org)" \
      --eval "(org-babel-tangle-file \"$src\")"
    echo "Done. Restart Emacs to load the new init.el."
  '';
in
{
  home.packages = [ emacs-tangle ];

  programs.emacs = {
    enable = true;
    package = pkgs.emacs-gtk;
    extraPackages = epkgs: with epkgs; [
      aggressive-indent
      all-the-icons
      all-the-icons-completion
      add-node-modules-path
      js2-mode
      prettier-js
      rjsx-mode
      typescript-mode
      web-mode
      csv-mode
      dockerfile-mode
      markdown-mode
      nginx-mode
      systemd
      terraform-mode
      toml-mode
      yaml-mode
      treesit-grammars.with-all-grammars
      avy
      dashboard
      diff-hl
      evil-anzu
      evil-goggles
      helpful
      highlight-indent-guides
      multiple-cursors
      rainbow-mode
      dap-mode
      ein
      poetry
      ob-restclient
      org-bullets
      org-download
      cape
      cider
      clj-refactor
      clojure-mode
      clojure-snippets
      consult-lsp
      consult-project-extra
      corfu
      coverage
      eat
      embark
      embark-consult
      evil
      evil-collection
      evil-commentary
      evil-matchit
      evil-surround
      expand-region
      feature-mode
      flycheck
      flycheck-clj-kondo
      htmlize
      json-mode
      ligature
      magit
      magit-section
      marginalia
      mixed-pitch
      modus-themes
      move-text
      nix-mode
      olivetti
      orderless
      org-superstar
      org-roam
      org-roam-ui
      paredit
      py-isort
      pytest
      python-black
      pyvenv
      rainbow-delimiters
      restclient
      smartparens
      transient
      treemacs
      treemacs-all-the-icons
      undo-tree
      vertico
      wgrep
      which-key
      origami
      yafolding
      yasnippet
      yasnippet-capf
      yasnippet-snippets
    ];
  };
}