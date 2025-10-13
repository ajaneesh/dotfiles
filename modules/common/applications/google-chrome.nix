{ config, pkgs, lib, ... }:

{
  options.chrome.enable = lib.mkEnableOption "Google Chrome browser";

  config = lib.mkIf config.chrome.enable {
    home.packages = [ pkgs.google-chrome ];

    xdg.desktopEntries = {
      "google-chrome" = {
        name = "Google Chrome";
        exec = "google-chrome-stable --force-device-scale-factor=0.75 --disable-gpu --disable-software-rasterizer --disable-gpu-sandbox --disable-features=VizDisplayCompositor";
        icon = "google-chrome";
        terminal = false;
        categories = [ "Network" "WebBrowser" ];
      };
    };

    # Font preferences for Default profile
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

    # Font preferences for Profile 1 (if it exists)
    xdg.configFile."google-chrome/Profile 1/Preferences".text = builtins.toJSON {
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
