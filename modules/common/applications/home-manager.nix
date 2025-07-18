{ config, pkgs, lib, ... }:

{
  imports = [
    ./i3.nix
  ];
  
  nixpkgs.config.allowUnfree = true;

  # This file contains common Home Manager packages and configurations
  # that are shared across all hosts.

  home.packages = [
    # ... (all your other packages)
    pkgs.dante
    pkgs.libsecret
  ] ++ (lib.optional (pkgs ? git-credential-libsecret) pkgs.git-credential-libsecret);

  programs.git = {
    enable = true;
    extraConfig = lib.mkIf (pkgs ? git-credential-libsecret) {
      credential.helper = "${pkgs.git-credential-libsecret}/bin/git-credential-libsecret";
    };
  };

  # Emacs Packages
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
      lsp-pyright
      magit
      magit-section
      marginalia
      mixed-pitch
      modus-themes
      move-text
      mu4e-alert
      nix-mode
      olivetti
      orderless
      org-superstar
      org-msg
      org-mime
      org-roam
      org-roam-ui
      paredit
      pkgs.emacsPackagesCustom.mu4e-dashboard
      pkgs.emacsPackagesCustom.emacs-claude-code
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
