{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    nodejs
    nodePackages.npm
    nodePackages.yarn
  ];

  # Manually create the ~/.npmrc file to set the prefix
  home.file.".npmrc".text = ''
    prefix = ${config.home.homeDirectory}/.npm-global
  '';

  # Ensure the global npm bin directory is in your PATH
  # This makes 'gemini' and other global npm packages discoverable
  home.sessionPath = [ "${config.home.homeDirectory}/.npm-global/bin" ];

}
