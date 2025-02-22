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
    ../../modules/common
    ../../modules/nixos
    ../../modules/wsl
    globals
    inputs.wsl.nixosModules.wsl
    inputs.home-manager.nixosModules.home-manager
    inputs.vscode-server.nixosModules.default
    inputs.agenix.nixosModules.age 
    ({ config, pkgs, ... }: {
      environment.systemPackages = with pkgs; [
        xorg.xhost
        xorg.xorgserver
        wayland
        mu

        # Theming
        adwaita-qt
        gtk-engine-murrine
        gtk_engines
        gsettings-desktop-schemas
        adwaita-icon-theme

        # Font improvements
        dejavu_fonts
        noto-fonts
        noto-fonts-emoji

        # Compositor for smooth rendering
        picom

        # Optional - notification daemon
        dunst
      ];

      # Font configuration
      fonts = {
        fontDir.enable = true;
        enableGhostscriptFonts = true;
         packages= with pkgs; [
          dejavu_fonts
          noto-fonts
          noto-fonts-emoji
        ];
      };
      services.emacs = {
 	enable = true;
 	defaultEditor = true;
 	# startupWithUserSession = true;  # This is important
 	package = pkgs.emacs;  # Ensure this matches your main emacs package
      };
      emacs.enable = true;
    })
    {
      # Core X server settings that don't depend on pkgs/runtime args
      services.xserver = {
        enable = true;
        displayManager.startx.enable = false;
        exportConfiguration = true;
        # Enable basic X server appearance improvements
        desktopManager.wallpaper.mode = "scale";
        
        # Enable a lightweight window manager
        windowManager.qtile = {
          enable = true;
        };
      };
      # GTK theme configuration
      programs.dconf.enable = true;
      
      # Qt theme to match GTK
      qt = {
        enable = true;
        platformTheme = "gtk2";
        style = "adwaita-dark";
      };
      # Environment variables are also static configuration
      environment.sessionVariables = {
        DISPLAY = ":0";
        LIBGL_ALWAYS_INDIRECT = "1";
        GTK_THEME = "Adwaita-dark";
      };
      services.vscode-server.enable = true;
      networking.hostName = "hydra";
      nixpkgs.overlays = overlays;
      identityFile = "/home/${globals.user}/.ssh/id_ed25519";
      gui.enable = true;
      theme = {
        colors = (import ../../colorscheme/gruvbox).dark;
        dark = true;
      };
      wallpaper = "${inputs.wallpapers}/gruvbox/road.jpg";
      gtk.theme.name = "Adwaita-dark";
      passwordHash = inputs.nixpkgs.lib.fileContents ../../misc/password.sha512;
      wsl = {
        enable = true;
        wslConf.automount.root = "/mnt";
        defaultUser = globals.user;
        startMenuLaunchers = true;
        nativeSystemd = true;
        wslConf.network.generateResolvConf = true; # Turn off if it breaks VPN
        interop.includePath = false; # Including Windows PATH will slow down Neovim command mode
      };
      virtualisation.docker = {
        enable = true;
        enableOnBoot = true;
      };
      users.users.nixos.extraGroups = [ "docker" ];
      # vscode.enable = true;
      age-manager.enable = true;
      email-manager = {
        enable = true;
        gmail = {
          enable = true;
          address = "ajaneesh.rajashekharaiah@ihx.in";
          realName = "Ajaneesh Rajashekharaiah";
        };
      };
      # neovim.enable = true;
      # mail.enable = true;
      # mail.aerc.enable = true;
      # mail.himalaya.enable = true;
      dotfiles.enable = true;
      lua.enable = true;
      clojure.enable = true;
      docker.enable = true;
      python.enable = true;
    }
  ];
}
