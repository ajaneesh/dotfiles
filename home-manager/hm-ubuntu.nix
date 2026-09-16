{ ... }:

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
