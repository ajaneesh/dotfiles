{ config, pkgs, lib, ... }:

{
  options.rust.enable = lib.mkEnableOption "Enable Rust development environment";

  config = lib.mkIf config.rust.enable {
    home.packages = with pkgs; [
      rustup
      wasm-pack
    ];
  };
}