{ config, pkgs, lib, ... }:

let
  google-chrome-with-flags = pkgs.writeShellScriptBin "google-chrome" ''
    #!${pkgs.runtimeShell}
    exec ${pkgs.google-chrome}/bin/google-chrome-stable --ozone-platform=x11 --disable-gpu --disable-software-rasterizer --disable-features=VizDisplayCompositor "$@"
  '';
in
{
  options.chrome.enable = lib.mkEnableOption "Google Chrome browser";

  config = lib.mkIf config.chrome.enable {
    home.packages = [ pkgs.google-chrome google-chrome-with-flags ];

    /*
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

    # Font preferences for Profile 2 (if it exists)
    xdg.configFile."google-chrome/Profile 5/Preferences".text = builtins.toJSON {
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
    */
  };
}