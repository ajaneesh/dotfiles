{ config, pkgs, lib, ... }:

let
  # Workaround flags for environments without proper GPU passthrough
  # (WSLg, Crostini); on native hosts `chrome` runs fully accelerated
  chromeFlags =
    if config.chrome.softwareRendering then
      " --ozone-platform=x11 --disable-gpu --disable-software-rasterizer --disable-features=VizDisplayCompositor --disable-dev-shm-usage"
    else
      "";
  google-chrome-with-flags = pkgs.writeShellScriptBin "chrome" ''
    #!${pkgs.runtimeShell}
    # Scale the whole browser UI (not just fonts) from the shared display.scale
    # knob. --force-device-scale-factor overrides Chrome's own DPI detection, so
    # there is no double-scaling with Xft.dpi. screen-scale = effective DPI / 96.
    scale=$(screen-scale 2>/dev/null || echo 1.0)
    exec ${pkgs.google-chrome}/bin/google-chrome-stable${chromeFlags} --force-device-scale-factor="$scale" "$@"
  '';
in
{
  options.chrome.enable = lib.mkEnableOption "Google Chrome browser";
  options.chrome.softwareRendering =
    lib.mkEnableOption "software rendering workarounds for virtualized X11 (WSL, Crostini)";

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