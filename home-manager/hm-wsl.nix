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
  wsl-vpnkit = {
    enable = true;
    vpnNetworks = [
      "172.19.4.0/24"
      "10.0.23.28/32"
      # Add more networks as needed
    ];
  };
}
