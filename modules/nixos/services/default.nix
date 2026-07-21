# This file imports all the other files in this directory for use as modules in
# my config.

{ ... }:
{

  imports = [
    ./gnupg.nix
    ./identity.nix
    ./secrets.nix
    ./sshd.nix
  ];
}
