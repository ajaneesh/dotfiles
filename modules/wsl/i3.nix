# Add this to your home-manager config or create a new file at modules/wsl/i3.nix

{
  config,
  pkgs,
  lib,
  ...
}:

{
  config = lib.mkIf (config.wsl.enable && config.gui.enable) {
    home-manager.users.${config.user} = {
      xsession.windowManager.i3 = {
        enable = true;
        config = {
          modifier = "Mod1"; # Windows key
          terminal = "xterm-with-config"; 
          
          # Basic startup applications
          startup = [
            { command = "feh --bg-fill ${config.wallpaper}"; always = true; notification = false; }
            # Add any WSL-specific startup items here
          ];
          
          # Simple default layout
          workspaceLayout = "tabbed";
          
          # Window decoration settings for WSL - simpler is better
          window = {
            border = 1;
            titlebar = false;
          };
          
          # Basic key bindings for a more minimal setup
          keybindings = let modifier = "Mod1"; in {
            "${modifier}+Return" = "exec --no-startup-id ${pkgs.xterm}/bin/xterm";

            "${modifier}+Shift+q" = "kill";
            "${modifier}+d" = "exec ${pkgs.dmenu}/bin/dmenu_run";
            
            # Window navigation
            "${modifier}+Left" = "focus left";
            "${modifier}+Down" = "focus down";
            "${modifier}+Up" = "focus up";
            "${modifier}+Right" = "focus right";
            
            # Moving windows
            "${modifier}+Shift+Left" = "move left";
            "${modifier}+Shift+Down" = "move down";
            "${modifier}+Shift+Up" = "move up";
            "${modifier}+Shift+Right" = "move right";
            
            # Layouts
            "${modifier}+h" = "split h";
            "${modifier}+v" = "split v";
            "${modifier}+f" = "fullscreen toggle";
            "${modifier}+s" = "layout stacking";
            "${modifier}+w" = "layout tabbed";
            "${modifier}+e" = "layout toggle split";
            
            # Floating
            "${modifier}+Shift+space" = "floating toggle";
            "${modifier}+space" = "focus mode_toggle";
            
            # Workspaces
            "${modifier}+1" = "workspace 1";
            "${modifier}+2" = "workspace 2";
            "${modifier}+3" = "workspace 3";
            "${modifier}+4" = "workspace 4";
            "${modifier}+5" = "workspace 5";
            
            "${modifier}+Shift+1" = "move container to workspace 1";
            "${modifier}+Shift+2" = "move container to workspace 2";
            "${modifier}+Shift+3" = "move container to workspace 3";
            "${modifier}+Shift+4" = "move container to workspace 4";
            "${modifier}+Shift+5" = "move container to workspace 5";
            
            # Restart and reload
            "${modifier}+Shift+c" = "reload";
            "${modifier}+Shift+r" = "restart";
            
            # Exit - simplified for WSL
            "${modifier}+Shift+e" = "exec i3-nagbar -t warning -m 'Exit i3?' -B 'Yes' 'i3-msg exit'";
          };
          
          # WSL-friendly modes
          modes = {
            resize = {
              "Left" = "resize shrink width 10 px";
              "Down" = "resize grow height 10 px";
              "Up" = "resize shrink height 10 px";
              "Right" = "resize grow width 10 px";
              "Escape" = "mode default";
              "Return" = "mode default";
            };
          };
          
          # Simple bar configuration
          bars = [{
            position = "bottom";
            statusCommand = "${pkgs.i3status}/bin/i3status";
            fonts = {
              names = [ "DejaVu Sans Mono" ];
              size = 10.0;
            };
          }];
        };
      };

      # Add a simple i3status configuration
      programs.i3status = {
        enable = true;
        general = {
          colors = true;
          color_good = "#8C9440";
          color_bad = "#A54242";
          color_degraded = "#DE935F";
        };
        modules = {
          "load" = {
            position = 1;
          };
          "disk /" = {
            position = 2;
          };
          "memory" = {
            position = 3;
            settings = {
              format = "%used";
            };
          };
          "tztime local" = {
            position = 4;
            settings = {
              format = "%Y-%m-%d %H:%M:%S";
            };
          };
        };
      };
    };
  };
}
