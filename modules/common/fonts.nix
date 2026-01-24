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

    # Enable font rendering improvements
    home.file.".config/fontconfig/conf.d/99-hm-rendering.conf".text = ''
      <?xml version='1.0'?>
      <!DOCTYPE fontconfig SYSTEM 'urn:fontconfig:fonts.dtd'>
      <fontconfig>
        <!-- Enable anti-aliasing -->
        <match target="font">
          <edit name="antialias" mode="assign">
            <bool>true</bool>
          </edit>
        </match>

        <!-- Use slight hinting -->
        <match target="font">
          <edit name="hinting" mode="assign">
            <bool>true</bool>
          </edit>
          <edit name="hintstyle" mode="assign">
            <const>hintslight</const>
          </edit>
        </match>

        <!-- Enable subpixel rendering (RGB) -->
        <match target="font">
          <edit name="rgba" mode="assign">
            <const>rgb</const>
          </edit>
        </match>

        <!-- Use LCD filter -->
        <match target="font">
          <edit name="lcdfilter" mode="assign">
            <const>lcddefault</const>
          </edit>
        </match>
      </fontconfig>
    '';

    home.packages = with pkgs; [
      meslo-lgs-nf
      emacs-all-the-icons-fonts
      jetbrains-mono
      hack-font
      nerd-fonts.hack
      dejavu_fonts
      noto-fonts
      noto-fonts-color-emoji
      source-sans-pro
    ];
  };
}
