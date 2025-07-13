{ config, pkgs, lib, inputs, overlays, globals, ... }: {
  # Home Manager configuration for Crostini

  home.username = globals.user;
  home.homeDirectory = "/home/${globals.user}";

  # This is required for home-manager to work standalone.
  # Please change this to the version you want to use.
  home.stateVersion = "24.05";

  # Import the crostini-specific module
  imports = [
    ../../modules/home-manager/common/default.nix # Import the new common module
  ];

  # Apply the common overlays
  nixpkgs.overlays = overlays;

  # You can add packages here if you want them to be available on this host
  # home.packages = with pkgs; [
  #   hello
  # ];
}