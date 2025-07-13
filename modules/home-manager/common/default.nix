{ config, pkgs, lib, ... }:

{
  imports = [
    ./i3.nix
  ];
  
  nixpkgs.config.allowUnfree = true;

  # This file contains common Home Manager packages and configurations
  # that are shared across all hosts.

  home.packages = with pkgs; [
    # Fonts
    pkgs.emacs-all-the-icons-fonts
    dejavu_fonts
    noto-fonts
    noto-fonts-emoji

    # Window Managers
    i3
    i3status
    i3lock
    dmenu
    sxhkd
    pkgs.xorg.xorgserver
    pkgs.xorg.setxkbmap
    pkgs.xorg.xkeyboardconfig

    # Core Utilities
    git
    vim
    wget
    curl
    htop
    ripgrep
    fzf
    eza
    bat
    delta
    difftastic
    dig
    fd
    killall
    inetutils
    jless
    jo
    jq
    lf
    osc
    qrencode
    rsync
    sd
    tealdeer
    tree
    vimv-rs
    unzip
    dua
    du-dust
    duf

    # Development
    age
    age-plugin-yubikey
    docker-compose
    docker
    docker-credential-helpers
    pass
    gnupg
    libffi
    openssl
    gcc
    cmake
    extra-cmake-modules
    gnumake
    poetry
    imagemagick
    postgresql_15
    pyright
    python310
    cargo
    rustc
    clippy
    fira-code-symbols
    nodejs_22
    jdk17
    clojure
    leiningen
    babashka
    clojure-lsp
    cider
    clj-kondo
    terraform
    terraform-ls
    tflint
    kubectl
    kubernetes-helm
    fluxcd
    kustomize
    k9s
    stylua
    sumneko-lua-language-server

    # Applications
    google-chrome
    claude-code
    _1password-cli
    (if pkgs.stdenv.isLinux then _1password-gui else null)
    discord
    firefox
    kitty
    wezterm
    alacritty
    xterm
    nsxiv
    mupdf
    zathura
    mpv
    obsidian
    qbittorrent
    slack
    yt-dlp
    aerc
    himalaya
    
    msmtp
    notmuch
    w3m
    dante
  ];

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
