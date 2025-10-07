{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    # Python
    python3Packages.python-lsp-server
  ];
}
