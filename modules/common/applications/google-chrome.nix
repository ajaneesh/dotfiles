{ config, pkgs, lib, ... }:

{
  options.chrome.enable = lib.mkEnableOption "Google Chrome browser";

  config = lib.mkIf config.chrome.enable {
    home.packages = [ pkgs.google-chrome ];

    xdg.desktopEntries = {
      "google-chrome" = {
        name = "Google Chrome";
        exec = "google-chrome-stable --force-device-scale-factor=1 --disable-gpu --disable-software-rasterizer --disable-gpu-sandbox --disable-features=VizDisplayCompositor";
        icon = "google-chrome";
        terminal = false;
        categories = [ "Network" "WebBrowser" ];
      };
    };

    xdg.configFile."google-chrome/Default/Preferences".text = builtins.toJSON {
      webkit = {
        webprefs = {
          fonts = {
            standard = {
              Zyyy = "Source Sans Pro";
            };
            sansserif = {
              Zyyy = "Source Sans Pro";
            };
            serif = {
              Zyyy = "DejaVu Serif";
            };
            fixed = {
              Zyyy = "JetBrains Mono";
            };
          };
        };
      };
    };
  };
}
