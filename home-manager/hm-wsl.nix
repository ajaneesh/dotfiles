{ ... }:

{
  imports = [
    ../modules/common/applications/xephyr.nix
    ../modules/common/applications/screenshots.nix
    ../modules/common/applications/wsl-vpnkit.nix
    ./hm-common.nix
  ];

  # Enable i3 with Xephyr for WSL
  xephyr.enable = true;

  # Enable screenshot tools
  screenshots.enable = true;

  # Enable WSL VPN routing through Windows
  wsl-vpnkit.enable = true;

  # WSL-specific directory shortcuts
  programs.zsh.shellAliases = {
    proj = "cd ~/projects";
    parakeet = "cd ~/projects/parakeet";
    dots = "cd ~/dotfiles";
  };
}
