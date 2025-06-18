{
  config,
  pkgs,
  lib,
  ...
}:

{
  config = lib.mkIf config.wsl.enable {
    # Disable display manager for WSL
    services.xserver.displayManager.lightdm.enable = lib.mkForce false;
    services.xserver.displayManager.gdm.enable = lib.mkForce false;
    services.xserver.enable = lib.mkForce false;
    
    # WSL-specific configurations
    
    # Ensure systemd compatibility
    # wsl.nativeSystemd = true;
    
    # Network configuration for WSL
    networking = {
      # Using nameserver from /etc/resolv.conf
      nameservers = lib.mkIf (!config.wsl.wslConf.network.generateResolvConf) [ "8.8.8.8" "1.1.1.1" ];
      
      # Disable wait online service which can cause issues in WSL
      networkmanager.enable = false;
    };
    
    # Disable services that can cause issues in WSL
    systemd.services = {
      # Disable services known to be problematic in WSL
      systemd-timesyncd.enable = false;
      systemd-resolved.enable = false;
    };
    
    # WSL environment variables
    environment.sessionVariables = {
      # For X11 applications - WSLg already sets DISPLAY
      DISPLAY = ":1";
      
      # Allow GUI applications to work properly
      LIBGL_ALWAYS_INDIRECT = "1";
      GDK_BACKEND = "x11";
      QT_QPA_PLATFORM = "x11";
      XDG_SESSION_TYPE = "x11";
      WINIT_UNIX_BACKEND = "x11";

      # Force software rendering for problematic apps
      WEZTERM_CONFIG_FILE = "/home/nixos/.config/wezterm/wezterm.lua";
      LIBGL_ALWAYS_SOFTWARE = "1";

      # WSL-specific paths for better integration
      WSL_INTEROP = "/run/WSL/";
      
      # For i3 usage in WSLg
      # QT_QPA_PLATFORM = "wayland";
      # SDL_VIDEODRIVER = "wayland";
      # _JAVA_AWT_WM_NONREPARENTING = "1";
      
      # Improve font rendering
      GDK_SCALE = "1";
      GDK_DPI_SCALE = "1";
    };

    
    # Shell integration for WSL
    programs.bash.shellInit = ''
      # WSL-specific shell setup
      if command -v wslpath >/dev/null 2>&1; then
        # Convert Windows paths to WSL paths
        wslpath_to_unix() {
          if [[ "$1" == /* ]]; then
            echo "$1"
          else
            wslpath -u "$1"
          fi
        }
        
        # Alias for easy navigation to Windows home
        alias winhome="cd $(wslpath -u $(powershell.exe -Command 'Write-Host -NoNewline $HOME' 2>/dev/null))"
      fi
    '';
    
    # GUI support for WSL
    environment.systemPackages = with pkgs; [
      # WSL-specific utilities
      wslu               # WSL utilities
      wsl-open           # Open Windows applications
      
      # X11 clipboard support
      xsel
      xclip
      
      # File manager
      file-roller
      
      # Basic GUI utilities
      xdg-utils
    ];
  };
}
