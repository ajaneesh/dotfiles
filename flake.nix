{
  description = "My system";

  # Other flakes that we want to pull from
  inputs = {

    # Used for system packages
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Used for specific stable packages
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.05";

    # Used for caddy plugins
    nixpkgs-caddy.url = "github:jpds/nixpkgs/caddy-external-plugins";

    # Used for MacOS system config
    darwin = {
      url = "github:lnl7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Used for Windows Subsystem for Linux compatibility
    wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Used for user packages and dotfiles
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs"; # Use system packages list for their inputs
    };

    # Provides declarative rust toolchains
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # vscode-server = {
    #   url = "github:nix-community/nixos-vscode-server";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
    # Community packages; used for Firefox extensions
    nur = {
      url = "github:nix-community/nur";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Use official Firefox binary for macOS
    firefox-darwin = {
      url = "github:bandithedoge/nixpkgs-firefox-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Better App install management in macOS
    mac-app-util = {
      url = "github:hraban/mac-app-util";
      inputs.nixpkgs.follows = "nixpkgs"; # Use system packages list for their inputs
    };

    # Manage disk format and partitioning
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixgl = {
      url = "github:guibou/nixGL";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Wallpapers
    wallpapers = {
      url = "gitlab:exorcist365/wallpapers";
      flake = false;
    };

    # Used to generate NixOS images for other platforms
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Convert Nix to Neovim config
    nix2vim = {
      url = "github:gytis-ivaskevicius/nix2vim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nvim-treesitter-src = {
      # https://github.com/nvim-treesitter/nvim-treesitter/tags
      url = "github:nvim-treesitter/nvim-treesitter/v0.9.2";
      flake = false;
    };
    telescope-nvim-src = {
      # https://github.com/nvim-telescope/telescope.nvim/releases
      url = "github:nvim-telescope/telescope.nvim/0.1.8";
      flake = false;
    };
    telescope-project-nvim-src = {
      url = "github:nvim-telescope/telescope-project.nvim";
      flake = false;
    };
    toggleterm-nvim-src = {
      # https://github.com/akinsho/toggleterm.nvim/tags
      url = "github:akinsho/toggleterm.nvim/v2.12.0";
      flake = false;
    };
    bufferline-nvim-src = {
      # https://github.com/akinsho/bufferline.nvim/releases
      url = "github:akinsho/bufferline.nvim/v4.6.1";
      flake = false;
    };
    nvim-tree-lua-src = {
      url = "github:kyazdani42/nvim-tree.lua";
      flake = false;
    };
    hmts-nvim-src = {
      url = "github:calops/hmts.nvim";
      flake = false;
    };
    fidget-nvim-src = {
      # https://github.com/j-hui/fidget.nvim/tags
      url = "github:j-hui/fidget.nvim/v1.4.5";
      flake = false;
    };
    nvim-lint-src = {
      url = "github:mfussenegger/nvim-lint";
      flake = false;
    };
    tiny-inline-diagnostic-nvim-src = {
      url = "github:rachartier/tiny-inline-diagnostic.nvim";
      flake = false;
    };
    snipe-nvim-src = {
      url = "github:leath-dub/snipe.nvim";
      flake = false;
    };

    # Tree-Sitter Grammars
    tree-sitter-bash = {
      url = "github:tree-sitter/tree-sitter-bash/master";
      flake = false;
    };
    tree-sitter-python = {
      url = "github:tree-sitter/tree-sitter-python/master";
      flake = false;
    };
    tree-sitter-lua = {
      url = "github:MunifTanjim/tree-sitter-lua/main";
      flake = false;
    };
    tree-sitter-ini = {
      url = "github:justinmk/tree-sitter-ini";
      flake = false;
    };
    tree-sitter-puppet = {
      url = "github:amaanq/tree-sitter-puppet";
      flake = false;
    };
    tree-sitter-rasi = {
      url = "github:Fymyte/tree-sitter-rasi";
      flake = false;
    };

    # MPV Scripts
    zenyd-mpv-scripts = {
      url = "github:zenyd/mpv-scripts";
      flake = false;
    };

    # Git alternative
    # Fixes: https://github.com/martinvonz/jj/issues/4784
    jujutsu = {
      url = "github:martinvonz/jj";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Ren and rep - CLI find and replace
    rep = {
      url = "github:robenkleene/rep-grep";
      flake = false;
    };
    ren = {
      url = "github:robenkleene/ren-find";
      flake = false;
    };

    gh-collaborators = {
      url = "github:katiem0/gh-collaborators";
      flake = false;
    };

    # Clipboard over SSH
    osc = {
      url = "github:theimpostor/osc/v0.4.6";
      flake = false;
    };

    # Nextcloud Apps
    nextcloud-news = {
      # https://github.com/nextcloud/news/releases
      url = "https://github.com/nextcloud/news/releases/download/25.0.0-alpha12/news.tar.gz";
      flake = false;
    };
    nextcloud-external = {
      # https://github.com/nextcloud-releases/external/releases
      url = "https://github.com/nextcloud-releases/external/releases/download/v5.5.2/external-v5.5.2.tar.gz";
      flake = false;
    };
    nextcloud-cookbook = {
      # https://github.com/christianlupus-nextcloud/cookbook-releases/releases/
      url = "https://github.com/christianlupus-nextcloud/cookbook-releases/releases/download/v0.11.2/cookbook-0.11.2.tar.gz";
      flake = false;
    };
    nextcloud-snappymail = {
      # https://github.com/the-djmaze/snappymail/releases
      # https://snappymail.eu/repository/nextcloud
      url = "https://snappymail.eu/repository/nextcloud/snappymail-2.38.2-nextcloud.tar.gz";
      # url = "https://github.com/nmasur/snappymail-nextcloud/releases/download/v2.36.3/snappymail-2.36.3-nextcloud.tar.gz";
      flake = false;
    };
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, ... }@inputs:

    let

      # Global configuration for my systems
      globals =
        let
          baseName = "nixos";
        in
        rec {
          user = "nixos";
          fullName = "NixOS";
          gitName = fullName;
          gitEmail = "";
          mail.server = "";
          mail.imapHost = "";
          mail.smtpHost = "";
          dotfilesRepo = "https://github.com/ajaneeshihx/dotfiles";
          hostnames = {
            audiobooks = "read.${baseName}";
            budget = "money.${baseName}";
            files = "files.${baseName}";
            git = "git.${baseName}";
            influxdb = "influxdb.${baseName}";
            irc = "irc.${baseName}";
            metrics = "metrics.${baseName}";
            minecraft = "minecraft.${baseName}";
            n8n = "n8n.${baseName}";
            notifications = "ntfy.${baseName}";
            prometheus = "prom.${baseName}";
            paperless = "paper.${baseName}";
            photos = "photos.${baseName}";
            secrets = "vault.${baseName}";
            stream = "stream.${baseName}";
            content = "cloud.${baseName}";
            books = "books.${baseName}";
            download = "download.${baseName}";
            status = "status.${baseName}";
            transmission = "transmission.${baseName}";
          };
        };

      # Common overlays to always use
      overlays = [
        inputs.nur.overlays.default
        inputs.nix2vim.overlay
        inputs.jujutsu.overlays.default # Fix: https://github.com/martinvonz/jj/issues/4784
        (import ./overlays/tree-sitter.nix inputs)
        (import ./overlays/mpv-scripts.nix inputs)
        (import ./overlays/nextcloud-apps.nix inputs)
        (import ./overlays/betterlockscreen.nix)
        (import ./overlays/fix-xss-lock.nix)
        (import ./overlays/gh-collaborators.nix inputs)
        (import ./overlays/osc.nix inputs)
        (import ./overlays/ren-rep.nix inputs)
        (import ./overlays/volnoti.nix)
        (import ./overlays/emacs-packages.nix)
        (import ./overlays/aws-overlay.nix)
        (import ./overlays/wsl-vpnkit.nix)
      ];

      # System types to support.
      supportedSystems = [
        "x86_64-linux"
        "x86_64-darwin"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in
    rec {

      # Contains my full system builds, including home-manager
      # nixos-rebuild switch --flake .#nixos-wsl
      nixosConfigurations = {
        nixos-wsl = import ./hosts/nixos-wsl { inherit inputs globals overlays; };
      };

      # No darwin configurations

      # For quickly applying home-manager settings with:
      # home-manager switch --flake .#hm-debian
      homeConfigurations = {
        hm-debian = inputs.home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            system = "x86_64-linux";
            overlays = overlays ++ [ inputs.rust-overlay.overlays.default ];
          };
          extraSpecialArgs = { inherit inputs overlays globals; };
          modules = [ ./home-manager/hm-debian.nix ];
        };
        hm-wsl = inputs.home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            system = "x86_64-linux";
            overlays = overlays ++ [ inputs.rust-overlay.overlays.default ];
          };
          extraSpecialArgs = { inherit inputs overlays globals; };
          modules = [ ./home-manager/hm-wsl.nix ];
        };
        hm-crostini = inputs.home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            system = "x86_64-linux";
            overlays = overlays ++ [
              inputs.rust-overlay.overlays.default
              inputs.nixgl.overlay
            ];
          };
          extraSpecialArgs = { inherit inputs overlays globals; };
          modules = [ ./home-manager/hm-crostini.nix ];
        };
      };

      # Disk formatting, only used once
      diskoConfigurations = {
        root = import ./disks/root.nix;
      };

      # No custom packages

      # Programs that can be run by calling this flake
      apps = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system overlays; };
        in
        import ./apps { inherit pkgs; }
      );

      # Development environments
      devShells = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system overlays; };
        in
        {

          # Used to run commands and edit files in this repo
          default = pkgs.mkShell {
            buildInputs = with pkgs; [
              git
              stylua
              nixfmt-rfc-style
              shfmt
              shellcheck
            ];
          };
        }
      );

      checks = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system overlays; };
        in
        {
        }
      );

      formatter = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system overlays; };
        in
        pkgs.nixfmt-rfc-style
      );

      # Templates for starting other projects quickly
      templates = rec {
        default = basic;
        basic = {
          path = ./templates/basic;
          description = "Basic program template";
        };
        poetry = {
          path = ./templates/poetry;
          description = "Poetry template";
        };
        python = {
          path = ./templates/python;
          description = "Legacy Python template";
        };
        haskell = {
          path = ./templates/haskell;
          description = "Haskell template";
        };
        rust = {
          path = ./templates/rust;
          description = "Rust template";
        };
      };
    };
}
