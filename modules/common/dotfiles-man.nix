{ config, pkgs, lib, ... }:

# `man dotfiles` - a build-time-generated overview of this machine's config.
#
# The source of truth is dotfiles-manual.md (readable Markdown). We convert it
# to a roff man page with go-md2man during the build and install it into the
# profile's man path, so `home-manager switch` regenerates it every time and it
# can never fall out of sync with the source. Volatile detail (keybindings,
# setup state) is delegated to the live `i3-keys` / `setup-status` commands
# rather than duplicated here.

let
  dotfilesManual = pkgs.runCommand "dotfiles-manual"
    { nativeBuildInputs = [ pkgs.go-md2man ]; }
    ''
      mkdir -p $out/share/man/man7
      go-md2man -in ${./dotfiles-manual.md} -out $out/share/man/man7/dotfiles.7
    '';
in
{
  home.packages = [ dotfilesManual ];
}
