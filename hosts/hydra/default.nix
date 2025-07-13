# The Hydra
# System configuration for WSL

# See [readme](../README.md) to explain how this file works.

{
  inputs,
  globals,
  overlays,
  ...
}:

inputs.nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  specialArgs = { };
  modules = [
    ../../modules/wsl
    ../../modules/home-manager/common # Import the new common module
    globals
    globals
    inputs.wsl.nixosModules.wsl
    inputs.home-manager.nixosModules.home-manager
    # inputs.vscode-server.nixosModules.default
    inputs.agenix.nixosModules.age 
    ({ config, pkgs, lib, ... }: {
      time.timeZone = "Asia/Kolkata";
      systemd.services.display-manager.enable = lib.mkForce false;
      
      # X Server configuration for WSLg
      services.xserver = {
        enable = lib.mkIf config.wsl.enable true;
        displayManager = {
          lightdm.enable = lib.mkIf config.wsl.enable false;
          startx.enable = false;  # Using WSLg's built-in display manager
        };
        # Enable i3 window manager
        windowManager.i3 = {
          enable = true;
          # No need for special WSL configurations here - basic setup is sufficient
        };
      };
      
      services.displayManager = {
        defaultSession = "none+i3";
      };

      unfreePackages = [
        "google-chrome"
        "claude-code"
      ];

      # Environment setup for WSLg
      

      # Font configuration
      fonts = {
        fontDir.enable = true;
        enableGhostscriptFonts = true;
        packages = with pkgs; [
          dejavu_fonts
          noto-fonts
          noto-fonts-emoji
        ];
      };

      # Emacs service configuration
      systemd.user.services.emacs = {
        description = "Emacs Daemon";
        wantedBy = [ "default.target" ];
        serviceConfig = {
          Type = "forking";
          ExecStart = "${pkgs.emacs}/bin/emacs --daemon";
          ExecStop = "${pkgs.emacs}/bin/emacsclient --eval '(kill-emacs)'";
          Restart = "on-failure";
        };
      };
      emacs.enable = true;

      # GTK theme configuration
      programs.dconf.enable = true;
      claudecode.enable = true;      
      # Qt theme to match GTK
      qt = {
        enable = true;
        platformTheme = "gtk2";
        style = "adwaita-dark";
      };

      # Enable VSCode server for WSL integration
      # services.vscode-server.enable = true;

      # Basic network config for WSL
      networking.hostName = "hydra";
      nixpkgs.overlays = overlays;
      identityFile = "/home/${globals.user}/.ssh/id_ed25519";
      
      # Enable GUI
      gui.enable = true;
      theme = {
        colors = (import ../../colorscheme/gruvbox).dark;
        dark = true;
      };
      wallpaper = "${inputs.wallpapers}/gruvbox/road.jpg";
      gtk.theme.name = "Adwaita-dark";
      
      # Password if needed
      passwordHash = inputs.nixpkgs.lib.fileContents ../../misc/password.sha512;
      
      # WSL-specific configuration
      wsl = {
        enable = true;
        wslConf.automount.root = "/mnt";
        defaultUser = globals.user;
        startMenuLaunchers = true;
        # nativeSystemd = true;
        wslConf.network.generateResolvConf = true;
        interop.includePath = false; # Including Windows PATH will slow down Neovim command mode
      };

      # Docker configuration
      virtualisation.docker = {
        enable = true;
        enableOnBoot = true;
      };
      users.users.nixos.extraGroups = [ "docker" ];

      # Other enabled features
      age-manager.enable = true;
      email-manager = {
        enable = true;
        gmail = {
          enable = true;
          address = "ajaneesh.rajashekharaiah@ihx.in";
          realName = "Ajaneesh Rajashekharaiah";
        };
      };

      # Dotfiles and development setup
      dotfiles.enable = true;
      lua.enable = true;
      clojure.enable = true;
      docker.enable = true;
      python.enable = true;
    })
  ];
}
