{ config, pkgs, lib, ... }:

{
  # Ensure the home-manager command is always available
  programs.home-manager.enable = true;

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
}
