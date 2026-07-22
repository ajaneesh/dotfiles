{ config, pkgs, lib, ... }:

{
  # Ensure the home-manager command is always available
  programs.home-manager.enable = true;

  nixpkgs.config.allowUnfree = true;

}
