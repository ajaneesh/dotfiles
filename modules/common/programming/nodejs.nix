{ config, pkgs, lib, ... }:

{
  options.nodejs.enable = lib.mkEnableOption "Node.js development environment";

  config = lib.mkIf config.nodejs.enable {
    home.packages = with pkgs; [
      nodejs_22
      yarn
      typescript-language-server
      vscode-langservers-extracted
      yaml-language-server
    ];

    # Manually create the ~/.npmrc file to set the prefix
    home.file.".npmrc".text = ''
      prefix = ${config.home.homeDirectory}/.npm-global
    '';

    # Ensure the global npm bin directory is in your PATH
    # This makes 'gemini' and other global npm packages discoverable
    home.sessionPath = [ "${config.home.homeDirectory}/.npm-global/bin" ];
  };
}
