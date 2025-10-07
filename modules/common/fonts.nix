{ config, pkgs, lib, ... }:

{
  options.fonts.enable = lib.mkEnableOption "Font configuration";

  config = lib.mkIf config.fonts.enable {
    fonts.fontconfig = {
      enable = true;
      defaultFonts = {
        sansSerif = [ "Source Sans Pro" "DejaVu Sans" ];
        serif = [ "DejaVu Serif" ];
        monospace = [ "JetBrains Mono" "Hack" "DejaVu Sans Mono" ];
      };
    };

    home.packages = with pkgs; [
      meslo-lgs-nf
      emacs-all-the-icons-fonts
      jetbrains-mono
      hack-font
      nerd-fonts.hack
      dejavu_fonts
      noto-fonts
      noto-fonts-emoji
      source-sans-pro
    ];
  };
}
