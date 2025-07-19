{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    # Python
    python3Packages.python-lsp-server

    # Web
    nodePackages.typescript-language-server
    nodePackages.vscode-langservers-extracted
    nodePackages.yaml-language-server
  ];
}
