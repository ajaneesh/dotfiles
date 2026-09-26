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

  # WSLg has no proper GPU passthrough; run Chrome with software rendering
  chrome.softwareRendering = true;

  # Xephyr/MobaXterm report no real panel size, so DPI auto-detection can't work
  # here. Pin the base DPI; tune sizing with display.scale (default 1.0).
  display.dpiOverride = 96;

  # WSL-specific directory shortcuts
  programs.zsh.shellAliases = {
    proj = "cd ~/projects";
    parakeet = "cd ~/projects/parakeet";
    dots = "cd ~/dotfiles";
  };
}
