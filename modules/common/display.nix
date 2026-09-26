{ config, pkgs, lib, ... }:

# Single source of truth for UI scale/DPI across the whole session, with ONE
# command to manage it: `display-scale`.
#
# The model: effective DPI = the display's real DPI x a scale knob, pushed into
# Xft.dpi (honored by urxvt, xterm, rofi, dmenu, GTK, and Emacs) and handed to
# the two apps that ignore Xft.dpi - wezterm (its own dpi) and Chrome
# (--force-device-scale-factor). So sizing stays consistent on any display, and
# "bigger/smaller" is one knob, portable across Debian/Ubuntu/Crostini/WSL.
#
# Scale precedence (highest first), all resolved by screen-dpi:
#   1. $DISPLAY_SCALE            - env, for one-off scripting/experiments
#   2. <state>/scale.session     - temporary override (`display temp/bigger/...`)
#   3. <state>/scale             - persistent per-machine default (`display set`)
#   4. display.scale (this file) - the Nix default
# where <state> = ${XDG_STATE_HOME:-~/.local/state}/dotfiles/display.
#
# The state files are machine-local *preference*, not config: the reproducible
# Nix default always remains the fallback.

let
  cfg = config.display;
  dpiOverrideStr = if cfg.dpiOverride == null then "" else toString cfg.dpiOverride;

  # Shell snippet (reused by several scripts) that resolves the active scale and
  # names the state directory/files.
  resolveScale = ''
    _state="''${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles/display"
    _persist="$_state/scale"
    _session="$_state/scale.session"
    resolve_scale() {
      if [ -n "''${DISPLAY_SCALE:-}" ]; then echo "$DISPLAY_SCALE"
      elif [ -f "$_session" ]; then cat "$_session"
      elif [ -f "$_persist" ]; then cat "$_persist"
      else echo "${toString cfg.scale}"; fi
    }
  '';

  # Effective DPI = physical DPI x resolved scale.
  screenDpi = pkgs.writeShellScriptBin "screen-dpi" ''
    ${resolveScale}
    scale=$(resolve_scale)
    override="''${SCREEN_DPI_OVERRIDE:-${dpiOverrideStr}}"
    if [ -n "$override" ]; then
      base="$override"
    else
      line=$(${pkgs.xrandr}/bin/xrandr --query 2>/dev/null | grep " connected primary" | head -1)
      [ -z "$line" ] && line=$(${pkgs.xrandr}/bin/xrandr --query 2>/dev/null | grep " connected" | head -1)
      px=$(printf '%s\n' "$line" | grep -oE '[0-9]+x[0-9]+\+[0-9]+\+[0-9]+' | head -1 | cut -dx -f1)
      mm=$(printf '%s\n' "$line" | grep -oE '[0-9]+mm x [0-9]+mm' | head -1 | grep -oE '^[0-9]+')
      if [ -n "$px" ] && [ -n "$mm" ] && [ "$mm" -gt 0 ]; then
        base=$(( px * 254 / (mm * 10) ))
      else
        base=96
      fi
    fi
    ${pkgs.gawk}/bin/awk -v b="$base" -v s="$scale" 'BEGIN { printf "%d\n", (b * s) + 0.5 }'
  '';

  # Device-scale-factor form (effective DPI / 96) for Chrome / GTK.
  screenScale = pkgs.writeShellScriptBin "screen-scale" ''
    dpi=$(${screenDpi}/bin/screen-dpi)
    ${pkgs.gawk}/bin/awk -v d="$dpi" 'BEGIN { printf "%.2f\n", d / 96 }'
  '';

  # Push the effective DPI into the X resource DB so Xft apps pick it up. Run at
  # session start (i3) and whenever the scale changes.
  displayApply = pkgs.writeShellScriptBin "display-apply" ''
    dpi=$(${screenDpi}/bin/screen-dpi)
    printf 'Xft.dpi: %s\n' "$dpi" | ${pkgs.xrdb}/bin/xrdb -merge
  '';

  # The one command to manage sizing. Everything else is an implementation detail.
  displayCmd = pkgs.writeShellScriptBin "display-scale" ''
    ${resolveScale}
    mkdir -p "$_state"
    apply() { ${displayApply}/bin/display-apply; }
    show() {
      local scale dpi factor src
      scale=$(resolve_scale); scale=$(${pkgs.gawk}/bin/awk -v s="$scale" 'BEGIN { printf "%g", s }')
      dpi=$(${screenDpi}/bin/screen-dpi); factor=$(${screenScale}/bin/screen-scale)
      if   [ -n "''${DISPLAY_SCALE:-}" ]; then src="env DISPLAY_SCALE"
      elif [ -f "$_session" ];           then src="temporary (this session)"
      elif [ -f "$_persist" ];           then src="persistent (this machine)"
      else                                    src="Nix default (display.scale)"; fi
      echo "Display scaling"
      echo "  current scale : $scale   ($src)"
      echo "  effective DPI : $dpi     (device-scale $factor)"
      echo
      echo "  display-scale set N       set this machine's default (persists, e.g. 0.8)"
      echo "  display-scale bigger      nudge up   +0.1   (temporary - for screen sharing)"
      echo "  display-scale smaller     nudge down -0.1   (temporary)"
      echo "  display-scale temp N      set a temporary scale for this session"
      echo "  display-scale reset       drop the temporary scale, back to the default"
      echo
      echo "  Lower = denser (more screen); higher = bigger. New app launches pick"
      echo "  it up; already-open wezterm zooms with Ctrl +/-. For meetings:"
      echo "  'display-scale bigger' a few times, then 'display-scale reset' after."
    }
    nudge() {
      local cur new
      cur=$(resolve_scale)
      new=$(${pkgs.gawk}/bin/awk -v c="$cur" -v d="$1" 'BEGIN { v=c+d; if (v<0.4) v=0.4; if (v>3) v=3; printf "%.2f\n", v }')
      echo "$new" > "$_session"; apply; echo "temporary scale -> $new  (display-scale reset to restore)"
    }
    case "''${1:-status}" in
      status|"") show ;;
      set)   [ -n "''${2:-}" ] || { echo "usage: display-scale set N" >&2; exit 1; }
             echo "$2" > "$_persist"; rm -f "$_session"; apply; echo "default scale for this machine -> $2" ;;
      temp)  [ -n "''${2:-}" ] || { echo "usage: display-scale temp N" >&2; exit 1; }
             echo "$2" > "$_session"; apply; echo "temporary scale -> $2  (display-scale reset to restore)" ;;
      bigger)  nudge 0.1 ;;
      smaller) nudge -0.1 ;;
      reset) rm -f "$_session"; apply; echo "temporary scale cleared -> back to $(resolve_scale)" ;;
      *) echo "unknown: $1" >&2; show >&2; exit 1 ;;
    esac
  '';
in
{
  options.display = {
    scale = lib.mkOption {
      type = lib.types.either lib.types.float lib.types.int;
      default = 1.0;
      example = 0.85;
      description = ''
        Nix default UI scale, relative to each display's real DPI. 1.0 =
        physically correct; <1 denser; >1 bigger. Portable - the same value means
        the same on every display. This is the fallback; per-machine tuning is
        done at runtime with `display set N` (no rebuild).
      '';
    };
    dpiOverride = lib.mkOption {
      type = lib.types.nullOr lib.types.int;
      default = null;
      example = 96;
      description = ''
        Force the base physical DPI instead of auto-detecting from xrandr. Use on
        hosts where the panel's physical size is unknowable (Xephyr, MobaXterm).
      '';
    };
  };

  config = {
    home.packages = [ screenDpi screenScale displayApply displayCmd ];
  };
}
