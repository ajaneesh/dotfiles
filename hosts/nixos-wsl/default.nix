{ inputs, globals, overlays, ... }:

inputs.nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  specialArgs = {
    inherit inputs globals overlays;
    pkgs-stable = import inputs.nixpkgs-stable { system = "x86_64-linux"; };
  };
  modules = [
    # Use the unified NixOS WSL profile
    ../../modules/nixos/profiles/nixos-wsl.nix
    
    # WSL specific configuration
    inputs.wsl.nixosModules.wsl
    {
      wsl = {
        enable = true;
        defaultUser = globals.user;
        startMenuLaunchers = true;
        wslConf.automount.root = "/mnt";
        wslConf.network.generateHosts = false;
        wslConf.network.generateResolvConf = false;
      };
    }
    
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