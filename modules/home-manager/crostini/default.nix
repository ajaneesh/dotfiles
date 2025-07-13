{ pkgs, ... }:

{
  home.packages = with pkgs; [
    htop
    ripgrep
    fzf
    eza
    bat
    git
  ];
}