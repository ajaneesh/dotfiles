{ config, pkgs, lib, ... }:

let
  cfg = config.wsl-vpnkit;

  # Script to configure VPN routes - only touches specified networks
  # Uses metric-based priority: our routes (no metric = 0) override
  # the mirrored routes (metric 102) without deleting them.
  # On removal, the original routes seamlessly take over.
  vpnRoutesScript = pkgs.writeShellScript "vpn-routes" ''
    #!/bin/bash
    set -e

    ACTION="$1"  # "add" or "del"

    # VPN networks to route through wsl-vpnkit (whitelist only)
    VPN_NETWORKS=(${lib.concatStringsSep " " (map (n: "\"${n}\"") cfg.vpnNetworks)})

    if [ "$ACTION" = "add" ]; then
      echo "Adding VPN routes (whitelist only)..."
      for network in "''${VPN_NETWORKS[@]}"; do
        # Add higher-priority route through wsl-vpnkit (metric 0 beats existing metric 102)
        # The original mirrored route via eth2 is preserved as fallback
        ip route add "$network" via 192.168.127.1 2>/dev/null || \
          ip route replace "$network" via 192.168.127.1 2>/dev/null || true
        echo "  + $network -> wsl-vpnkit"
      done

      # Remove any default route wsl-vpnkit may have added
      # This prevents ALL traffic from going through VPN (SSL inspection issues)
      if ip route show default | grep -q "192.168.127.1"; then
        echo ""
        echo "Removing wsl-vpnkit default route (prevents SSL interception)..."
        ip route del default via 192.168.127.1 2>/dev/null || true
        echo "  + Default route cleaned up"
      fi

    elif [ "$ACTION" = "del" ]; then
      echo "Removing VPN routes..."
      for network in "''${VPN_NETWORKS[@]}"; do
        ip route del "$network" via 192.168.127.1 2>/dev/null || true
        echo "  - Removed $network (original route still active)"
      done
    fi
  '';

  # Main vpn-start script
  vpnStartScript = pkgs.writeShellScriptBin "vpn-start" ''
    #!/bin/bash
    set -e

    WSL_VPNKIT_DIR="${pkgs.wsl-vpnkit}"

    echo "========================================"
    echo "  WSL VPN Router (Exception-based)"
    echo "========================================"
    echo ""
    echo "This routes ONLY these networks through VPN:"
    ${lib.concatMapStringsSep "\n" (n: "echo \"  - ${n}\"") cfg.vpnNetworks}
    echo ""
    echo "All other traffic uses normal internet."
    echo ""
    echo "Make sure VPN is connected on Windows first!"
    echo ""

    # Check if already running
    if pgrep -f "wsl-gvproxy" > /dev/null; then
      echo "wsl-vpnkit appears to be already running."
      echo "Use 'vpn-stop' first, or 'vpn-status' to check."
      exit 1
    fi

    # Start wsl-vpnkit in the background with output logged
    echo "Starting wsl-vpnkit..."
    sudo VMEXEC_PATH="$WSL_VPNKIT_DIR/lib/wsl-vpnkit/wsl-vm" \
         GVPROXY_PATH="$WSL_VPNKIT_DIR/lib/wsl-vpnkit/wsl-gvproxy.exe" \
         "$WSL_VPNKIT_DIR/bin/wsl-vpnkit" > /tmp/wsl-vpnkit.log 2>&1 &

    # Wait for wsl-vpnkit to initialize
    echo "Waiting for wsl-vpnkit gateway (192.168.127.1)..."
    for i in {1..10}; do
      if ip route show | grep -q "192.168.127.1"; then
        echo "Gateway is ready."
        break
      fi
      sleep 1
    done

    # Remove any default route wsl-vpnkit added during startup
    sudo ip route del default via 192.168.127.1 2>/dev/null || true

    # Configure VPN routes (whitelist only)
    echo ""
    sudo ${vpnRoutesScript} add

    # Wait briefly and clean up again - wsl-vpnkit may re-add default route
    sleep 2
    if ip route show default | grep -q "192.168.127.1"; then
      echo "Cleaning up wsl-vpnkit default route (added after init)..."
      sudo ip route del default via 192.168.127.1 2>/dev/null || true
    fi

    echo ""
    echo "========================================"
    echo "  VPN routing is now active!"
    echo "========================================"
    echo ""
    echo "Commands:"
    echo "  vpn-status  - Check status and routes"
    echo "  vpn-stop    - Stop VPN routing"
    echo "  vpn-test    - Test VPN connectivity"
    echo ""
  '';

  # Stop script
  vpnStopScript = pkgs.writeShellScriptBin "vpn-stop" ''
    #!/bin/bash

    echo "Stopping wsl-vpnkit..."

    # Remove our VPN exception routes
    sudo ${vpnRoutesScript} del 2>/dev/null || true

    # Kill wsl-vpnkit processes
    sudo pkill -f "wsl-gvproxy" 2>/dev/null || true
    sudo pkill -f "wsl-vm" 2>/dev/null || true
    sudo pkill -f "wsl-vpnkit" 2>/dev/null || true

    # Clean up any remaining routes via 192.168.127.1
    echo ""
    echo "Cleaning up any remaining wsl-vpnkit routes..."
    ip route show | grep "192.168.127.1" | while read route; do
      sudo ip route del $route 2>/dev/null || true
      echo "  - Removed: $route"
    done

    echo ""
    echo "Verifying original routes are intact..."
    ORIGINAL=$(ip route show | grep "172.27.241.1" | wc -l)
    echo "  $ORIGINAL mirrored routes via eth2 still active."
    echo ""
    echo "wsl-vpnkit stopped. Normal routing restored."
  '';

  # Status script
  vpnStatusScript = pkgs.writeShellScriptBin "vpn-status" ''
    #!/bin/bash

    echo "========================================"
    echo "  WSL VPN Status"
    echo "========================================"
    echo ""

    if pgrep -f "wsl-gvproxy" > /dev/null; then
      echo "Status: ✓ RUNNING"
    else
      echo "Status: ✗ STOPPED"
    fi

    echo ""
    echo "VPN Routes (via 192.168.127.1):"
    ROUTES=$(ip route show | grep "192.168.127.1" || true)
    if [ -n "$ROUTES" ]; then
      echo "$ROUTES" | while read line; do
        echo "  ✓ $line"
      done
    else
      echo "  (none)"
    fi

    echo ""
    echo "Configured VPN Networks:"
    ${lib.concatMapStringsSep "\n" (n: "echo \"  - ${n}\"") cfg.vpnNetworks}
  '';

  # Test script
  vpnTestScript = pkgs.writeShellScriptBin "vpn-test" ''
    #!/bin/bash

    echo "Testing VPN connectivity..."
    echo ""

    # Test internet (should work normally)
    echo "1. Testing internet (google.com)..."
    if curl -s --connect-timeout 5 https://google.com > /dev/null; then
      echo "   ✓ Internet: OK"
    else
      echo "   ✗ Internet: FAILED"
    fi

    echo ""
    echo "2. Testing VPN routes..."
    ${lib.concatMapStringsSep "\n" (n: ''
    echo "   Testing route to ${n}..."
    if ip route get ${lib.head (lib.splitString "/" n)} 2>/dev/null | grep -q "192.168.127.1"; then
      echo "   ✓ ${n} -> via wsl-vpnkit"
    else
      echo "   ✗ ${n} -> NOT via wsl-vpnkit"
    fi
    '') cfg.vpnNetworks}

    echo ""
    echo "3. To test actual VPN resource, run:"
    echo "   curl -v https://your-vpn-resource --connect-timeout 10"
  '';

in
{
  options.wsl-vpnkit = {
    enable = lib.mkEnableOption "WSL VPN routing through Windows";

    vpnNetworks = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "172.19.4.0/24" "172.19.14.0/24" ];
      description = ''
        List of VPN network CIDRs to route through wsl-vpnkit.
        ONLY these networks will be routed through VPN.
        All other traffic uses normal internet routing.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.wsl-vpnkit
      vpnStartScript
      vpnStopScript
      vpnStatusScript
      vpnTestScript
    ];

    # Add shell aliases
    programs.zsh.initContent = lib.mkAfter ''
      # WSL VPN aliases
      alias vpn='vpn-status'
    '';
  };
}
