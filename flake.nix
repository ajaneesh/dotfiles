{
  description = "My system";

  # Other flakes that we want to pull from
  inputs = {

    # Used for system packages
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

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

    # OpenGL wrappers for running GUI apps on non-NixOS hosts (Crostini)
    nixgl = {
      url = "github:guibou/nixGL";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs =
    { nixpkgs, ... }@inputs:

    let

      # Global configuration for my systems
      globals = {
        user = "nixos";
        fullName = "Ajaneesh Rajashekharaiah";
      };

      # Common overlays to always use
      overlays = [
        (import ./overlays/emacs-packages.nix)
        (import ./overlays/tree-sitter-tsx.nix)
        (import ./overlays/aws-overlay.nix)
        (import ./overlays/wsl-vpnkit.nix)
      ];

      # System types to support.
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in
    rec {

      # Contains my full system builds, including home-manager
      # nixos-rebuild switch --flake .#nixos-wsl
      nixosConfigurations = {
        nixos-wsl = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit inputs globals;
            overlays = overlays ++ [ inputs.rust-overlay.overlays.default ];
          };
          modules = [ ./hosts/nixos-wsl ];
        };
      };

      # For quickly applying home-manager settings with:
      # home-manager switch --flake .#hm-wsl
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

      # Verify that every profile still evaluates and builds:
      # nix flake check (--no-build to only evaluate)
      checks.x86_64-linux = {
        hm-wsl = homeConfigurations.hm-wsl.activationPackage;
        hm-crostini = homeConfigurations.hm-crostini.activationPackage;
        hm-debian = homeConfigurations.hm-debian.activationPackage;
      };

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
