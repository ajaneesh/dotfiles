{ config, pkgs, lib, inputs, overlays, globals, ... }: {
  # Unified Home Manager configuration for all machines
  # This replaces the duplicated crostini/tempest configurations
  
  home.username = globals.user;
  home.homeDirectory = "/home/${globals.user}";
  home.stateVersion = "24.05";
  
  # Import common modules
  imports = [
    # Common applications and configurations
    ../modules/common/applications/home-manager.nix
    ../modules/common/applications/age.nix
    ../modules/common/applications/i3.nix
  ];
  
  # Enable i3 window manager
  i3.enable = true;
  
  # Apply overlays and config for standalone use
  nixpkgs.overlays = overlays;
  nixpkgs.config.allowUnfree = true;
  
  # Enable font management
  fonts.fontconfig.enable = true;
  
  # Git configuration with age secrets
  programs.git = {
    userName = "Your Name"; # Will be overridden by age secrets
    userEmail = "your.email@example.com"; # Will be overridden by age secrets
  };
  
  # Shell configuration - ZSH ONLY
  programs.zsh = {
    enable = true;
    shellAliases = {
      # Git aliases with age secrets
      git-commit = ''git -c user.name="$(age-get-secret git-name 2>/dev/null || echo 'Your Name')" -c user.email="$(age-get-secret git-email 2>/dev/null || echo 'your.email@example.com')" commit'';
      git-commit-signed = ''git -c user.name="$(age-get-secret git-name 2>/dev/null || echo 'Your Name')" -c user.email="$(age-get-secret git-email 2>/dev/null || echo 'your.email@example.com')" commit -S'';
    };
  };
  
  # Common applications for all machines
  home.packages = with pkgs; [
    # Core applications (available on all machines)
    git
    
    # Desktop applications (will work on all machines with i3+Xephyr)  
    nautilus       # File manager
    _1password     # Password manager
    keybase        # Keybase client
    charm          # Development tools
    
    # i3 and Xephyr dependencies
    xorg.xorgserver  # Provides Xephyr
    rofi             # Application launcher
  ];
}