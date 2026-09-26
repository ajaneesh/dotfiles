{ pkgs, ... }:

{
  imports = [
    ../modules/common/applications/i3.nix
    ../modules/common/applications/screenshots.nix
    ../modules/common/applications/native-x-session.nix
    ./hm-common.nix
  ];

  # Native i3 on apt-based Ubuntu (work machine).
  #
  # This is an independent sibling of hm-debian: it reuses the same native-i3
  # building blocks (i3.nix, screenshots, native-x-session) but shares no
  # package list with it. Work-specific tooling stays here; home stuff stays
  # in hm-debian. The shared dev/work base (git, docker, aws, gcloud, gh,
  # glab, node, rust, clojure, claude-code, postgresql, jq, ...) comes from
  # hm-common.
  i3.enable = true;
  screenshots.enable = true;

  # Native X bootstrap: .xinitrc, startx service, and the `x11-setup` helper
  # (run `x11-setup` once to `apt install xorg xinit i3lock` + PAM config).
  nativeXSession.enable = true;

  # Unlike WSL/Crostini, Ubuntu has a real GPU, so Chrome uses hardware
  # rendering (we deliberately do NOT set chrome.softwareRendering here).

  # Sizing: one knob, relative to each display's real DPI (see display.nix).
  # 1.0 = physically correct; lower for a denser desktop. Starting default here;
  # override at runtime with `display-scale set N`.
  display.scale = 0.75;

  # Multi-monitor. Native Ubuntu drives real outputs (no Xephyr container), so
  # i3 spans them automatically. To PIN workspaces to specific monitors, fill in
  # your real output names (run `xrandr --query | grep ' connected'` on the box)
  # and uncomment. Names are host-specific, which is why this lives here, not in
  # the shared i3 module. `primary` is a portable fallback.
  #
  # xsession.windowManager.i3.config.workspaceOutputAssign = [
  #   { workspace = "1"; output = "DP-1"; }
  #   { workspace = "2"; output = "DP-1"; }
  #   { workspace = "3"; output = "HDMI-1"; }
  #   { workspace = "4"; output = "HDMI-1"; }
  # ];
  #
  # Arrange the outputs at session start (adjust names/positions), or use
  # autorandr (installed below) to save/restore per-setup layouts automatically:
  # xsession.windowManager.i3.config.startup = [
  #   { command = "xrandr --output DP-1 --primary --auto --output HDMI-1 --auto --right-of DP-1"; always = true; notification = false; }
  # ];
  home.packages = with pkgs; [
    autorandr   # save/restore monitor layouts per physical setup
    arandr      # GUI to arrange outputs and generate the xrandr command
  ];

  # Work directory shortcuts (this is the work box).
  programs.zsh.shellAliases = {
    proj = "cd ~/projects";
    dots = "cd ~/dotfiles";
  };

  # Work-only packages that aren't already in hm-common go here. Fill in as
  # you discover what the job needs — nothing here leaks into hm-debian.
  #
  # home.packages = with pkgs; [
  #   kubectl
  #   # <corporate VPN client>, a specific IDE, etc.
  # ];
}
