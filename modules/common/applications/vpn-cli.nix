{ config, pkgs, lib, ... }:

# Thin CLI wrappers around nmcli for the OpenVPN profiles stored in the system
# NetworkManager (e.g. the Privado servers imported from .ovpn). No applet, no
# gnome-keyring, no secret agent: store each profile's password in the
# connection once with
#   nmcli connection modify <profile> vpn.data "password-flags=0" \
#                                     vpn.secrets "password=<pw>"
# and these scripts bring the tunnel up/down headlessly.
#
# NB: nmcli/awk/grep are called UNPINNED (from PATH), not via ${pkgs...}, on
# purpose. The daemon these talk to is Debian's apt NetworkManager, so we want
# its matching apt nmcli client (/usr/bin/nmcli) - pinning pkgs.networkmanager
# would pull the whole Nix NM daemon closure back in for no benefit.

{
  options = {
    vpnCli.enable = lib.mkEnableOption "nmcli VPN wrapper scripts (vpn-up/vpn-down/vpn-status)";
  };

  config = lib.mkIf config.vpnCli.enable {
    home.packages = [
      # vpn-up [name|substring]
      #   No arg : connect if there's exactly one VPN profile, else list them.
      #   Arg    : connect to the single profile whose name contains the string
      #            (case-insensitive); ambiguous or no match just lists options.
      #   Drops any other already-active VPN first so tunnels don't stack.
      (pkgs.writeShellScriptBin "vpn-up" ''
        query="''${1:-}"
        mapfile -t vpns < <(nmcli -t -f NAME,TYPE connection show | awk -F: '$2=="vpn"{print $1}')
        if [ "''${#vpns[@]}" -eq 0 ]; then
          echo "No VPN profiles found in NetworkManager." >&2
          exit 1
        fi

        if [ -z "$query" ]; then
          if [ "''${#vpns[@]}" -eq 1 ]; then
            target="''${vpns[0]}"
          else
            echo "Multiple VPN profiles - pass a name or substring:" >&2
            printf '  %s\n' "''${vpns[@]}" >&2
            exit 1
          fi
        else
          matches=()
          for v in "''${vpns[@]}"; do
            case "''${v,,}" in *"''${query,,}"*) matches+=("$v") ;; esac
          done
          if [ "''${#matches[@]}" -eq 0 ]; then
            echo "No VPN profile matches '$query'. Available:" >&2
            printf '  %s\n' "''${vpns[@]}" >&2
            exit 1
          fi
          if [ "''${#matches[@]}" -gt 1 ]; then
            echo "'$query' matches multiple profiles:" >&2
            printf '  %s\n' "''${matches[@]}" >&2
            exit 1
          fi
          target="''${matches[0]}"
        fi

        # Drop any other active VPN so we don't stack tunnels.
        nmcli -t -f NAME,TYPE connection show --active | awk -F: '$2=="vpn"{print $1}' | \
          while read -r a; do
            [ "$a" = "$target" ] || { echo "Disconnecting $a..."; nmcli connection down "$a" >/dev/null 2>&1 || true; }
          done

        echo "Connecting $target..."
        nmcli connection up "$target"
      '')

      # vpn-down [name|substring]
      #   No arg : disconnect every active VPN.
      #   Arg    : disconnect active VPNs whose name contains the string.
      (pkgs.writeShellScriptBin "vpn-down" ''
        query="''${1:-}"
        active="$(nmcli -t -f NAME,TYPE connection show --active | awk -F: '$2=="vpn"{print $1}')"
        if [ -z "$active" ]; then
          echo "No active VPN connection."
          exit 0
        fi
        if [ -n "$query" ]; then
          active="$(printf '%s\n' "$active" | grep -i -- "$query" || true)"
          if [ -z "$active" ]; then
            echo "No active VPN matches '$query'." >&2
            exit 1
          fi
        fi
        printf '%s\n' "$active" | while read -r a; do
          echo "Disconnecting $a..."
          nmcli connection down "$a"
        done
      '')

      # vpn-status - show the connected VPN (if any) and list all VPN profiles.
      (pkgs.writeShellScriptBin "vpn-status" ''
        active="$(nmcli -t -f NAME,TYPE connection show --active | awk -F: '$2=="vpn"{print $1}')"
        echo "VPN status"
        echo "=========="
        if [ -n "$active" ]; then
          printf '%s\n' "$active" | while read -r a; do echo "  connected : $a"; done
          dev="$(nmcli -t -f GENERAL.DEVICES connection show "$(printf '%s' "$active" | head -n1)" 2>/dev/null | cut -d: -f2)"
          [ -n "$dev" ] && echo "  device    : $dev"
        else
          echo "  not connected"
        fi
        echo ""
        echo "Profiles (vpn-up <substring> to connect):"
        nmcli -t -f NAME,TYPE connection show | awk -F: '$2=="vpn"{print "  "$1}'
      '')
    ];
  };
}
