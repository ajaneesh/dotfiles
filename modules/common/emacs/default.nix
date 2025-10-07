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
        (texlive.combine {
          inherit (texlive) 
            scheme-minimal  # Bare minimum
            latex-bin       # LaTeX binaries
            latex           # Basic LaTeX packages
            dvipng          # DVI to PNG converter
            dvisvgm         # Alternative DVI converter
          # Any other TeX packages you might need
          ;
        })
        # Language servers for Eglot
        python3Packages.python-lsp-server  # pylsp for Python
        nodePackages.typescript-language-server  # TypeScript/JavaScript LSP
        nodePackages.vscode-langservers-extracted  # HTML/CSS/JSON LSP
        nodePackages.yaml-language-server  # YAML LSP
        terraform-ls  # Terraform LSP
      ];

      programs.emacs = {
        enable = true;
        package = pkgs.emacs-gtk;
        # package = (pkgs.emacs.override { withXwidgets = true; withGTK3 = true; });
	      extraPackages = epkgs: with epkgs; [
          aggressive-indent
          all-the-icons
          all-the-icons
          all-the-icons-completion
          # JavaScript/TypeScript packages
          add-node-modules-path
          js2-mode
          prettier-js
          rjsx-mode
          typescript-mode
          web-mode
          # Config file packages
          csv-mode
          dockerfile-mode
          markdown-mode
          nginx-mode
          systemd
          terraform-mode
          toml-mode
          yaml-mode
          # Tree-sitter packages
          treesit-grammars.with-all-grammars
          # Productivity packages
          avy
          dashboard
          diff-hl
          evil-anzu
          evil-goggles
          helpful
          highlight-indent-guides
          multiple-cursors
          rainbow-mode
          # Python enhancements
          dap-mode
          ein
          poetry
          # Org enhancements
          ob-restclient
          org-bullets
          org-download
          # Existing packages
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
          lsp-pyright
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
          org-msg
          org-mime
          org-roam
          org-roam-ui
          paredit
          pkgs.emacsPackagesCustom.emacs-claude-code
          pkgs.emacsPackagesCustom.org-notion
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
          # Folding packages
          origami
          yafolding
          yasnippet
          yasnippet-capf
          yasnippet-snippets
	      ];
      };

      home.file."org/roam/.keep".text = "";
      
    };

  };
}
