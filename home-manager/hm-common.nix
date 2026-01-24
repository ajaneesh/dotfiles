{ config, pkgs, lib, inputs, overlays, globals, ... }: {
  # Unified Home Manager configuration for all machines
  
  home.username = globals.user;
  home.homeDirectory = "/home/${globals.user}";
  home.stateVersion = "24.05";
  
  # Import common modules
  imports = [
    # Core applications and configurations
    ../modules/common/applications/home-manager.nix
    ../modules/common/applications/age.nix
    ../modules/common/applications/google-chrome.nix
    ../modules/common/shell.nix
    ../modules/common/git.nix
    ../modules/common/emacs.nix
    ../modules/common/terminals.nix
    ../modules/common/fonts.nix
    
    # Programming languages and tools
    ../modules/common/programming/clojure.nix
    ../modules/common/programming/claudecode.nix
    ../modules/common/programming/nodejs.nix
    ../modules/common/programming/language-servers.nix
    ../modules/common/programming/rust.nix
    ../modules/common/programming/devcontainers.nix
    ../modules/common/programming/docker.nix
    ../modules/common/programming/aws.nix
  ];
  
  # Enable claude-code
  claudecode.enable = true;
  clojure.enable = true;
  docker.enable = true;
  rust.enable = true;
  devcontainers.enable = true;
  nodejs.enable = true;

  chrome.enable = true;

  aws = {
    enable = true;
    disableTests = true;
  };
  
  fonts.enable = true;
  
  # Apply overlays and config for standalone use
  nixpkgs.overlays = overlays;
  nixpkgs.config.allowUnfree = true;

  # Common applications for all machines
  home.packages = with pkgs; [
    google-cloud-sdk
    postgresql
    gemini-cli
    firefox

    # Terminal info and utilities
    ncurses          # Terminal capabilities
    jq               # JSON processor
  ];
}
