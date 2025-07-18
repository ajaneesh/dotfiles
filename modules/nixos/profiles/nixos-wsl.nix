{ config, pkgs, lib, inputs, overlays, globals, ... }: {
  # Unified NixOS WSL configuration profile
  # This contains WSL-specific system configurations
  
  # Basic system configuration
  system.stateVersion = "24.05";
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  
  # User configuration
  users.users.${globals.user} = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = [ "wheel" "docker" ];
    hashedPassword = inputs.nixpkgs.lib.fileContents ../../../misc/password.sha512;
  };
  
  # Time zone configuration
  time.timeZone = "Asia/Kolkata";
  
  # ZSH as system shell
  programs.zsh.enable = true;
  
  # Docker configuration for WSL
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
  };
  
  # System services
  services.openssh.enable = true;
  
  # Overlays
  nixpkgs.overlays = overlays;
  
  # Basic network config
  networking.hostName = "nixos-wsl";
  
  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  
  # Home-manager integration is handled by the host configuration
}