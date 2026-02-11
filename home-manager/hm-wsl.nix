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
      "172.65.65.48/32"
      "172.17.65.209/32"
      "172.17.65.145/32"
      "172.17.65.71/32"
      "172.17.3.121/32"
      "172.17.3.24/32"
      "172.19.14.109/32"
      "172.19.14.162/32"
      "172.19.14.12/32"
      # Add more networks as needed
    ];
  };
}
