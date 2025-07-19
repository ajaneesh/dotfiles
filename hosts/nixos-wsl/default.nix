{ inputs, globals, overlays, ... }:

inputs.nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  specialArgs = {
    inherit inputs globals overlays;
    pkgs-stable = import inputs.nixpkgs-stable { system = "x86_64-linux"; };
  };
  modules = [
    # WSL specific configuration
    inputs.wsl.nixosModules.wsl
    
    # Combined NixOS WSL configuration (merged from profile)
    ({ config, pkgs, lib, ... }: {
      # Basic system configuration
      system.stateVersion = "24.05";
      nix.settings.experimental-features = [ "nix-command" "flakes" ];
      
      # WSL configuration
      wsl = {
        enable = true;
        defaultUser = globals.user;
        startMenuLaunchers = true;
        wslConf.automount.root = "/mnt";
        wslConf.network.generateHosts = false;
        wslConf.network.generateResolvConf = false;
      };
      
      # User configuration
      users.users.${globals.user} = {
        isNormalUser = true;
        shell = pkgs.zsh;
        extraGroups = [ "wheel" "docker" ];
        hashedPassword = inputs.nixpkgs.lib.fileContents ../../misc/password.sha512;
      };
      
      # Time zone configuration
      time.timeZone = "Asia/Kolkata";
      
      # ZSH as system shell
      programs.zsh.enable = true;
      
      # Docker configuration for WSL
      virtualisation.docker = {
        enable = true;
        enableOnBoot = true;
      };
      
      # System services
      services.openssh.enable = true;
      
      # Overlays
      nixpkgs.overlays = overlays;
      
      # Network configuration for WSL
      networking = {
        hostName = "nixos-wsl";
        # Using nameserver from /etc/resolv.conf, fallback to public DNS
        nameservers = lib.mkIf (!config.wsl.wslConf.network.generateResolvConf) [ "8.8.8.8" "1.1.1.1" ];
        
        # Disable wait online service which can cause issues in WSL
        networkmanager.enable = false;
      };
      
      # Allow unfree packages
      nixpkgs.config.allowUnfree = true;
      
      # WSL-specific system integrations (from integration.nix)
      
      # Disable display manager and X server for WSL
      services.xserver.displayManager.lightdm.enable = lib.mkForce false;
      services.displayManager.gdm.enable = lib.mkForce false;
      services.xserver.enable = lib.mkForce false;
      
      # Disable services that can cause issues in WSL
      systemd.services = {
        systemd-timesyncd.enable = false;
        systemd-resolved.enable = false;
      };
      
      # Disable other problematic services for WSL
      services.geoclue2.enable = lib.mkForce false;
      location.provider = lib.mkForce "manual";
      services.localtimed.enable = lib.mkForce false;
      
      # WSL environment variables for GUI applications
      environment.sessionVariables = {
        # For X11 applications - WSLg integration
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
        
        # Improve font rendering
        GDK_SCALE = "1";
        GDK_DPI_SCALE = "1";
      };
      
      # WSL-specific system packages
      environment.systemPackages = with pkgs; [
        # WSL utilities
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
      
      # Shell integration for WSL (ZSH version of bash integration)
      programs.zsh.shellInit = ''
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
    })
    
    # Home Manager integration with unified profile
    inputs.home-manager.nixosModules.home-manager
    {
      home-manager = {
        useGlobalPkgs = false;  # Allow home-manager to handle its own nixpkgs config
        useUserPackages = true;
        extraSpecialArgs = { inherit inputs overlays globals; };
        users.${globals.user} = import ../../home-manager/hm-common.nix;
      };
    }
  ];
}