{ config, pkgs, lib, ... }:

let
  cfg = config.wsl-vpnkit;

  # Script to configure VPN routes dynamically.
  # Detects all WSL-mirrored VPN routes (metric 102 via a shared gateway)
  # and reroutes them through wsl-vpnkit.
  vpnRoutesScript = pkgs.writeShellScript "vpn-routes" ''
    #!/bin/bash
    set -e

    ACTION="$1"  # "add" or "del"

    if [ "$ACTION" = "add" ]; then
      # Detect the mirrored VPN gateway (shared by all metric 102 routes)
      MIRROR_GW=$(ip route show | grep "metric 102" | grep "via" | head -1 | awk '{print $3}')
      if [ -z "$MIRROR_GW" ]; then
        echo "No mirrored VPN routes detected (no metric 102 routes with a gateway)."
        echo "Is the VPN connected on Windows?"
        exit 1
      fi

      MIRROR_DEV=$(ip route show | grep "metric 102" | grep "via" | head -1 | awk '{print $5}')
      echo "Detected mirrored VPN gateway: $MIRROR_GW dev $MIRROR_DEV"
      echo ""

      # Save gateway info for status/stop
      echo "$MIRROR_GW $MIRROR_DEV" > /tmp/wsl-vpnkit-mirror-gw

      echo "Adding VPN routes for all mirrored destinations..."
      COUNT=0
      ip route show | grep "via $MIRROR_GW" | grep "metric 102" | awk '{print $1}' | while read dest; do
        ip route add "$dest" via 192.168.127.1 2>/dev/null || true
        echo "  + $dest -> wsl-vpnkit"
        COUNT=$((COUNT + 1))
      done

      # Remove any default route wsl-vpnkit may have added
      if ip route show default | grep -q "192.168.127.1"; then
        echo ""
        echo "Removing wsl-vpnkit default route (prevents SSL interception)..."
        ip route del default via 192.168.127.1 2>/dev/null || true
      fi

    elif [ "$ACTION" = "del" ]; then
      echo "Removing all wsl-vpnkit routes..."
      ip route show | grep "via 192.168.127.1" | grep -v "192.168.127.0" | awk '{print $1}' | while read dest; do
        ip route del "$dest" via 192.168.127.1 2>/dev/null || true
        echo "  - $dest"
      done
      rm -f /tmp/wsl-vpnkit-mirror-gw
    fi
  '';

  # Helper to save and restore the original default route
  restoreDefaultRoute = ''
    # Restore original default route if it was lost
    if ! ip route show default | grep -qv "192.168.127.1"; then
      if [ -n "$ORIG_DEFAULT_GW" ] && [ -n "$ORIG_DEFAULT_DEV" ]; then
        echo "Restoring original default route via $ORIG_DEFAULT_GW dev $ORIG_DEFAULT_DEV..."
        sudo ip route add default via "$ORIG_DEFAULT_GW" dev "$ORIG_DEFAULT_DEV" 2>/dev/null || true
      fi
    fi
  '';

  # Main vpn-start script
  vpnStartScript = pkgs.writeShellScriptBin "vpn-start" ''
    #!/bin/bash
    set -e

    WSL_VPNKIT_DIR="${pkgs.wsl-vpnkit}"

    echo "========================================"
    echo "  WSL VPN Router (Auto-detect)"
    echo "========================================"
    echo ""
    echo "Routes all mirrored VPN destinations through wsl-vpnkit."
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

    # Save the original default route before wsl-vpnkit can replace it
    ORIG_DEFAULT_GW=$(ip route show default | grep -v "192.168.127.1" | head -1 | awk '{print $3}')
    ORIG_DEFAULT_DEV=$(ip route show default | grep -v "192.168.127.1" | head -1 | awk '{print $5}')
    echo "Saved original default route: via $ORIG_DEFAULT_GW dev $ORIG_DEFAULT_DEV"

    # Persist for vpn-stop to use
    echo "$ORIG_DEFAULT_GW $ORIG_DEFAULT_DEV" > /tmp/wsl-vpnkit-orig-default-route

    # Start wsl-vpnkit in the background with output logged
    # Pass WSL2_TAP_NAME and WSL2_GATEWAY_IP so wsl-vpnkit restores the
    # correct default route when it shuts down (it defaults to eth0 which
    # doesn't exist in mirrored networking mode)
    echo "Starting wsl-vpnkit..."
    sudo VMEXEC_PATH="$WSL_VPNKIT_DIR/lib/wsl-vpnkit/wsl-vm" \
         GVPROXY_PATH="$WSL_VPNKIT_DIR/lib/wsl-vpnkit/wsl-gvproxy.exe" \
         WSL2_TAP_NAME="$ORIG_DEFAULT_DEV" \
         WSL2_GATEWAY_IP="$ORIG_DEFAULT_GW" \
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
    ${restoreDefaultRoute}

    # Configure VPN routes (auto-detect all mirrored VPN destinations)
    echo ""
    sudo ${vpnRoutesScript} add

    # Wait briefly and clean up again - wsl-vpnkit may re-add default route
    sleep 2
    if ip route show default | grep -q "192.168.127.1"; then
      echo "Cleaning up wsl-vpnkit default route (added after init)..."
      sudo ip route del default via 192.168.127.1 2>/dev/null || true
    fi
    ${restoreDefaultRoute}

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

    # Load saved default route
    ORIG_DEFAULT_GW=""
    ORIG_DEFAULT_DEV=""
    if [ -f /tmp/wsl-vpnkit-orig-default-route ]; then
      read ORIG_DEFAULT_GW ORIG_DEFAULT_DEV < /tmp/wsl-vpnkit-orig-default-route
    fi

    # Remove all wsl-vpnkit routes
    sudo ${vpnRoutesScript} del 2>/dev/null || true

    # Kill wsl-vpnkit processes
    sudo pkill -f "wsl-gvproxy" 2>/dev/null || true
    sudo pkill -f "wsl-vm" 2>/dev/null || true
    sudo pkill -f "wsl-vpnkit" 2>/dev/null || true

    # Wait for processes to fully die and finish their own cleanup
    sleep 3

    # Clean up any remaining routes via 192.168.127.1
    echo ""
    echo "Cleaning up any remaining wsl-vpnkit routes..."
    ip route show | grep "192.168.127.1" | while read route; do
      sudo ip route del $route 2>/dev/null || true
      echo "  - Removed: $route"
    done

    # Ensure default route exists (wsl-vpnkit's cleanup may have restored it
    # on the wrong interface, or failed to restore it at all)
    if [ -n "$ORIG_DEFAULT_GW" ] && [ -n "$ORIG_DEFAULT_DEV" ]; then
      sudo ip route replace default via "$ORIG_DEFAULT_GW" dev "$ORIG_DEFAULT_DEV" 2>/dev/null || \
        sudo ip route add default via "$ORIG_DEFAULT_GW" dev "$ORIG_DEFAULT_DEV" 2>/dev/null || true
    else
      if ! ip route show default | grep -q .; then
        echo ""
        echo "WARNING: No default route found and no saved route to restore."
        echo "You may need to manually add one, e.g.:"
        echo "  sudo ip route add default via 192.168.1.1 dev eth4"
      fi
    fi

    rm -f /tmp/wsl-vpnkit-orig-default-route

    echo ""
    echo "Verifying original routes are intact..."
    MIRROR_ROUTES=$(ip route show | grep "metric 102" | wc -l)
    echo "  $MIRROR_ROUTES mirrored VPN routes still active."
    DEFAULT=$(ip route show default)
    if [ -n "$DEFAULT" ]; then
      echo "  Default route: $DEFAULT"
    else
      echo "  WARNING: No default route!"
    fi
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
    echo "VPN Routes (via wsl-vpnkit):"
    ROUTES=$(ip route show | grep "via 192.168.127.1" | grep -v "192.168.127.0" || true)
    if [ -n "$ROUTES" ]; then
      echo "$ROUTES" | while read line; do
        echo "  ✓ $line"
      done
    else
      echo "  (none)"
    fi

    echo ""
    echo "Mirrored VPN routes (via Windows):"
    MIRROR=$(ip route show | grep "metric 102" | grep "via" || true)
    if [ -n "$MIRROR" ]; then
      echo "$MIRROR" | wc -l | xargs -I{} echo "  {} routes detected"
    else
      echo "  (none - is the VPN connected on Windows?)"
    fi
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
    # Check a sample of vpnkit routes
    VPNKIT_DESTS=$(ip route show | grep "via 192.168.127.1" | grep -v "192.168.127.0" | awk '{print $1}' || true)
    if [ -n "$VPNKIT_DESTS" ]; then
      TOTAL=$(echo "$VPNKIT_DESTS" | wc -l)
      echo "   $TOTAL destinations routed through wsl-vpnkit"
      echo "$VPNKIT_DESTS" | head -5 | while read dest; do
        echo "   ✓ $dest -> via wsl-vpnkit"
      done
      if [ "$TOTAL" -gt 5 ]; then
        echo "   ... and $((TOTAL - 5)) more"
      fi
    else
      echo "   ✗ No routes via wsl-vpnkit"
    fi

    echo ""
    echo "3. To test actual VPN resource, run:"
    echo "   curl -v https://your-vpn-resource --connect-timeout 10"
  '';

in
{
  options.wsl-vpnkit = {
    enable = lib.mkEnableOption "WSL VPN routing through Windows";
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
