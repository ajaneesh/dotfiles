{ config, pkgs, lib, inputs, overlays, globals, ... }: {
  # Home Manager configuration for Crostini

  home.username = globals.user;
  home.homeDirectory = "/home/${globals.user}";

  # This is required for home-manager to work standalone.
  # Please change this to the version you want to use.
  home.stateVersion = "24.05";

  # Import the crostini-specific module
  imports = [
    ../../modules/home-manager/crostini/i3.nix
    ../../modules/home-manager/crostini/i3-desktop.nix
    ../../modules/home-manager/crostini/start-i3.nix
    ../../modules/home-manager/crostini/sxhkdrc.nix
    ../../modules/home-manager/common/default.nix # Import the new common module
    ../../modules/home-manager/common/age.nix
  ];

  # Apply the common overlays
  nixpkgs.overlays = overlays;

  # Enable font management for Home Manager
  fonts.fontconfig.enable = true;

  # You can add packages here if you want them to be available on this host
  # home.packages = with pkgs; [
  #   hello
  # ];

  # Git configuration will be set via shell scripts that read from age secrets
  programs.git = {
    userName = "Your Name"; # Placeholder - will be overridden by shell init
    userEmail = "your.email@example.com"; # Placeholder - will be overridden by shell init
  };

  # Add shell aliases that use secrets when available (maintains reproducibility)
  programs.bash.shellAliases = {
    git-commit = ''git -c user.name="$(age-get-secret git-name 2>/dev/null || echo 'Your Name')" -c user.email="$(age-get-secret git-email 2>/dev/null || echo 'your.email@example.com')" commit'';
    git-commit-signed = ''git -c user.name="$(age-get-secret git-name 2>/dev/null || echo 'Your Name')" -c user.email="$(age-get-secret git-email 2>/dev/null || echo 'your.email@example.com')" commit -S'';
  };
}