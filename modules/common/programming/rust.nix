{ config, pkgs, lib, ... }:

{
  options.rust.enable = lib.mkEnableOption "Enable Rust development environment";

  config = lib.mkIf config.rust.enable {
    home.packages = with pkgs;
      let
        # Define a custom Rust toolchain that includes the wasm target
        rustToolchain = pkgs.rust-bin.stable."1.90.0".default.override {
          targets = [ "wasm32-unknown-unknown" ];
          extensions = [ "rust-src" ]; # Often needed for code completion
        };
      in
      [
        # This package provides cargo, rustc, etc., with the wasm target
        rustToolchain

        # wasm-pack and gcc are still included as before
        wasm-pack
        gcc
      ];
  };
}
