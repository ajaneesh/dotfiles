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
    ({ config, pkgs, ... }: {
        services.vscode-server.enable = true;
	environment.systemPackages = with pkgs; [
          xorg.xorgserver
          wayland
      	];
        services.xserver.enable = true;
        services.emacs.enable = true;
    })
    {
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
      emacs.enable = true;
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
