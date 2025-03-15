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
            "${modifier}+Return" = "exec --no-startup-id xterm";
            "${modifier}+d" = "exec --no-startup-id ${pkgs.rofi}/bin/rofi -modes run -show run";

            "${modifier}+Shift+x" = "kill";
            #"${modifier}+d" = "exec ${pkgs.dmenu}/bin/dmenu_run";
            "${modifier}+Shift+f" = "fullscreen toggle global";

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
            
            # Resize window with vim keys...
            "${modifier}+Shift+h" = "resize shrink width 5 px or 5 ppt";
            "${modifier}+Shift+j" = "resize grow height 5 px or 5 ppt";
            "${modifier}+Shift+k" = "resize shrink height 5 px or 5 ppt";
            "${modifier}+Shift+l" = "resize grow width 5 px or 5 ppt";

            "${modifier}+Shift+1" = "move container to workspace 1";
            "${modifier}+Shift+2" = "move container to workspace 2";
            "${modifier}+Shift+3" = "move container to workspace 3";
            "${modifier}+Shift+4" = "move container to workspace 4";
            "${modifier}+Shift+5" = "move container to workspace 5";
            
            # Layouts
            "${modifier}+h" = "split h";
            "${modifier}+v" = "split v";
            "${modifier}+f" = "fullscreen toggle";
            "${modifier}+s" = "layout stacking";
            "${modifier}+w" = "layout tabbed";
            "${modifier}+e" = "layout toggle split";
            
            # Workspaces
            "${modifier}+1" = "workspace 1";
            "${modifier}+2" = "workspace 2; mode default";
            "${modifier}+3" = "workspace 3; mode default";
            "${modifier}+4" = "workspace 4; mode default";
            "${modifier}+5" = "workspace 5; mode default";
            
            # Restart and reload
            "${modifier}+Shift+q" = "reload";
            "${modifier}+Shift+r" = "restart";
            "${modifier}+Shift+s" = "exec --no-startup-id i3-resurrect save";
            "${modifier}+Shift+t" = "exec --no-startup-id i3-resurrect restore";

            "${modifier}+Esc" = "mode default";
            "${modifier}+0" = "mode emacs";
            
            # Exit - simplified for WSL
            "${modifier}+Shift+e" = "exec i3-nagbar -t warning -m 'Exit i3?' -B 'Yes' 'i3-msg exit'";

            # This should ideally not be required if i3 can detect Emca  
            # Manual toggle for emacs mode
            # bindsym $mod+e mode "emacs"            
            
            # # Unbind specific keybindings when focused on Emacs
            # bindsym --release $mod+h [class="Emacs"] nop
            # bindsym --release $mod+j [class="Emacs"] nop
            # bindsym --release $mod+k [class="Emacs"] nop
            # bindsym --release $mod+l [class="Emacs"] nop

            # # Example: Unbind specific problematic combinations
            # bindsym --release $mod+Shift+h [class="Emacs"] nop
            # bindsym --release $mod+Shift+j [class="Emacs"] nop
            # bindsym --release $mod+Control+k [class="Emacs"] nop
 
            # # Create a mode with no bindings (except to exit)
            # mode "passthrough" {
            #     bindsym $mod+F12 mode "default"
            # }
 
            # # Bind F12 to enter passthrough mode
            # bindsym $mod+F12 mode "passthrough"
            
          };

          modes = {
            "emacs" = let 
                modifier = "Mod1"; # Windows key
            in {    
                 # Window navigation
                "${modifier}+v" = "focus left";
                "${modifier}+b" = "focus down";
                "${modifier}+n" = "focus up";
                "${modifier}+m" = "focus right";
            
                # Workspaces
                "${modifier}+1" = "workspace 1";
                "${modifier}+2" = "workspace 2; mode default";
                "${modifier}+3" = "workspace 3; mode default";
                "${modifier}+4" = "workspace 4; mode default";
                "${modifier}+5" = "workspace 5; mode default";
            
                # Add a keybinding to exit emacs mode
      	        "${modifier}+Esc" = "mode default";
	              "${modifier}+0" = "mode emacs";
             
            };

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
              names = [ "JetBrains Mono" ];
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
