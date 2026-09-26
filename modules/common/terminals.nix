{ config, pkgs, lib, ... }:

let
  # Software (CPU) rendering for the terminal on virtualized / indirect X where
  # there is no usable OpenGL (WSL/WSLg, Xephyr, MobaXterm, Crostini). Defaults
  # to the same signal Chrome uses, so the constrained profiles need no extra
  # flag - they already set chrome.softwareRendering.
  swRender = config.terminals.softwareRendering;

  # wezterm is a GPU/GL application. On non-NixOS hosts it cannot find the
  # distro's libEGL/GL drivers and crashes at window creation ("with_egl_lib
  # failed: libEGL.so.1 ... cannot open shared object file"). nixGL injects the
  # right GL libraries - the same fix already used for the Crostini media apps.
  # urxvt/xterm are pure X11 and never need this. On NixOS, GL is found natively,
  # so wrapGL should be false there (see hosts/nixos-wsl).
  wrapGL = config.terminals.wrapGL;
  weztermCmd =
    if wrapGL
    then "${pkgs.nixgl.nixGLIntel}/bin/nixGLIntel ${pkgs.wezterm}/bin/wezterm"
    else "${pkgs.wezterm}/bin/wezterm";

  # Base terminal font point size. Physical scaling is handled session-wide by
  # Xft.dpi (urxvt/xterm) and by wezterm's own dpi (see display.nix), so this is
  # a fixed point size, not a per-display calculation. $TERM_FONT_SIZE overrides
  # it for a one-off launch.
  baseFontSize = "11";
  termFontSize = pkgs.writeShellScriptBin "term-fontsize" ''
    echo "''${TERM_FONT_SIZE:-${baseFontSize}}"
  '';

  termXterm = pkgs.writeShellScriptBin "term-xterm" ''
    size=$(${termFontSize}/bin/term-fontsize)
    exec ${pkgs.xterm}/bin/xterm \
      -fa "JetBrains Mono" -fs "$size" \
      -bg "#1d1f21" -fg "#c5c8c6" \
      -cr "#c5c8c6" \
      -e ${pkgs.zsh}/bin/zsh "$@"
  '';

  termUrxvt = pkgs.writeShellScriptBin "term-urxvt" ''
    size=$(${termFontSize}/bin/term-fontsize)
    ${pkgs.xrdb}/bin/xrdb -merge ~/.Xresources 2>/dev/null || true
    exec ${pkgs.rxvt-unicode}/bin/urxvt -fn "xft:Hack Nerd Font:size=$size" "$@"
  '';

  termWezterm = pkgs.writeShellScriptBin "term-wezterm" ''
    export WEZTERM_FONT_SIZE=$(${termFontSize}/bin/term-fontsize)
    # wezterm ignores Xft.dpi, so hand it the same effective DPI everything else
    # uses (from display.nix's screen-dpi).
    export WEZTERM_DPI=$(screen-dpi 2>/dev/null || echo 96)
    exec ${weztermCmd} "$@"
  '';

  # Default terminal dispatcher (honours $TERMINAL, defaults to wezterm).
  terminal = pkgs.writeShellScriptBin "terminal" ''
    case "''${TERMINAL:-wezterm}" in
      xterm)   exec ${termXterm}/bin/term-xterm "$@" ;;
      urxvt)   exec ${termUrxvt}/bin/term-urxvt "$@" ;;
      wezterm) exec ${termWezterm}/bin/term-wezterm "$@" ;;
      *)       exec ${termWezterm}/bin/term-wezterm "$@" ;;
    esac
  '';
in
{
  options.terminals.softwareRendering = lib.mkOption {
    type = lib.types.bool;
    default = config.chrome.softwareRendering;
    description = ''
      Render the terminal with CPU (software) instead of the GPU, for
      virtualized/indirect X hosts (WSL, Xephyr, Crostini) that lack usable
      OpenGL. Defaults to chrome.softwareRendering so it tracks the same hosts.
    '';
  };

  options.terminals.wrapGL = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = ''
      Wrap wezterm with nixGL so it can find the host's OpenGL/EGL drivers.
      Required on non-NixOS hosts (Debian, Ubuntu, Crostini) where a nixpkgs GL
      app otherwise crashes at window creation. Set false on NixOS, where the GL
      drivers are found natively.
    '';
  };

  config = {
    home.packages = with pkgs; [
      # Terminal options
      xterm            # Bare fallback terminal
      rxvt-unicode     # Lightweight X11 fallback (works over any X)
      wezterm          # Primary: rich, GPU on native / software elsewhere

      # Wrapper scripts (defined above): adaptive font size + backend selection
      termFontSize
      termXterm
      termUrxvt
      termWezterm
      terminal
    ];

    # .Xresources for rxvt-unicode. Note: term-urxvt passes an explicit -fn with
    # the adaptive size, so the URxvt.font line here is just a manual-launch
    # default; colours/behaviour below always apply.
    home.file.".Xresources".text = ''
      ! XTerm color scheme (Tomorrow Night)
      *.foreground:   #c5c8c6
      *.background:   #1d1f21
      *.cursorColor:  #c5c8c6
      *.color0:       #282a2e
      *.color8:       #373b41
      *.color1:       #a54242
      *.color9:       #cc6666
      *.color2:       #8c9440
      *.color10:      #b5bd68
      *.color3:       #de935f
      *.color11:      #f0c674
      *.color4:       #F5F5DC
      *.color12:      #F5F5DC
      *.color5:       #85678f
      *.color13:      #b294bb
      *.color6:       #5e8d87
      *.color14:      #8abeb7
      *.color7:       #707880
      *.color15:      #c5c8c6

      ! URxvt color scheme (Tomorrow Night)
      URxvt.foreground:   #c5c8c6
      URxvt.background:   #1d1f21
      URxvt.cursorColor:  #c5c8c6

      ! black
      URxvt.color0:       #282a2e
      URxvt.color8:       #373b41

      ! red
      URxvt.color1:       #a54242
      URxvt.color9:       #cc6666

      ! green
      URxvt.color2:       #8c9440
      URxvt.color10:      #b5bd68

      ! yellow
      URxvt.color3:       #de935f
      URxvt.color11:      #f0c674

      ! blue
      URxvt.color4:       #F5F5DC
      URxvt.color12:      #F5F5DC

      ! magenta
      URxvt.color5:       #85678f
      URxvt.color13:      #b294bb

      ! cyan
      URxvt.color6:       #5e8d87
      URxvt.color14:      #8abeb7

      ! white
      URxvt.color7:       #707880
      URxvt.color15:      #c5c8c6

      !! URxvt Appearance
      URxvt.letterSpace: 0
      URxvt.lineSpace: 0
      URxvt.geometry: 92x24
      URxvt.internalBorder: 6
      URxvt.cursorBlink: true
      URxvt.cursorUnderline: false
      URxvt.saveline: 2048
      URxvt.scrollBar: false
      URxvt.scrollBar_right: false
      URxvt.urgentOnBell: true
      URxvt.depth: 24
      URxvt.iso14755: false
      URxvt.font: xft:Hack Nerd Font:size=8
      URxvt.keysym.M-c: perl:clipboard:copy
      URxvt.keysym.M-v: perl:clipboard:paste
      URxvt.keysym.M-C-v: perl:clipboard:paste_escaped

      ! Copy/paste with Control+Insert and Shift+Insert
      URxvt.keysym.Control-Insert: eval:selection_to_clipboard
      URxvt.keysym.Shift-Insert: eval:paste_clipboard

      ! Ensure the clipboard extension is loaded
      URxvt.perl-ext-common: default,clipboard,url-select,keyboard-select
      URxvt.clipboard.autocopy: true
    '';

    # WezTerm configuration
    xdg.configFile."wezterm/wezterm.lua".text = ''
      local wezterm = require 'wezterm'
      local config = {}

      -- Font. Size is chosen per-display by the term-wezterm launcher (see
      -- term-fontsize) and passed via WEZTERM_FONT_SIZE; fall back otherwise.
      config.font = wezterm.font('Hack Nerd Font')
      config.font_size = tonumber(os.getenv('WEZTERM_FONT_SIZE')) or 11.0

      -- wezterm does not read Xft.dpi, so left alone it auto-detects the raw
      -- panel DPI and renders LARGER than every Xft app (the "different scale"
      -- effect). Match the session's effective DPI: prefer WEZTERM_DPI (set by
      -- term-wezterm), else ask screen-dpi directly so it is correct even when
      -- wezterm is launched some other way.
      local dpi = tonumber(os.getenv('WEZTERM_DPI'))
      if not dpi then
        local ok, out = pcall(function()
          local success, stdout = wezterm.run_child_process({ 'screen-dpi' })
          if success then return stdout end
          return nil
        end)
        if ok and out then dpi = tonumber(out:match('%d+')) end
      end
      if dpi then config.dpi = dpi end

      -- Color scheme
      config.color_scheme = 'Tomorrow Night'

      -- Window configuration
      config.initial_rows = 24
      config.initial_cols = 80

      -- No tab bar: on i3 we open a new window (Alt+Return) instead of wezterm
      -- tabs, so the bar is just wasted vertical space.
      config.enable_tab_bar = false

      -- Disable ligatures for compatibility
      config.harfbuzz_features = { 'calt=0', 'clig=0', 'liga=0' }

      -- Rendering backend: GPU (OpenGL) on native hosts; CPU (Software) on
      -- virtualized/indirect X (WSL/Xephyr/Crostini) with no usable GL. This is
      -- the setting that makes wezterm actually work on those hosts.
      config.front_end = '${if swRender then "Software" else "OpenGL"}'

      -- Don't manage the SSH agent socket (noisy/failing on these hosts).
      config.mux_enable_ssh_agent = false

      -- Key bindings
      config.keys = {
        -- Copy/paste
        { key = 'c', mods = 'ALT', action = wezterm.action.CopyTo 'Clipboard' },
        { key = 'v', mods = 'ALT', action = wezterm.action.PasteFrom 'Clipboard' },
      }

      return config
    '';

    # Environment variables for terminal selection
    home.sessionVariables = {
      # Default terminal (can be overridden per shell)
      TERMINAL = "wezterm";
    };
  };
}
