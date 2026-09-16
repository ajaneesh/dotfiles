{ config, pkgs, lib, ... }:

# Self-reporting first-time setup.
#
# Some things can't be declared in Nix because they're either secrets or need
# distro (apt) packages with setuid that Nix can't provide on non-NixOS:
#   - git-identity-setup : your per-directory name/email (~/.config/git/identity-*)
#   - gcm-setup          : the passphraseless gpg key + pass credential store
#   - x11-setup          : apt xorg/xinit/i3lock + PAM (native-X profiles only)
#
# Rather than expect you to remember these, this module gives you:
#   1. `setup-status`  — run anytime to see what's done and what's left.
#   2. a build-time hint — `home-manager switch` prints the pending steps, but
#      only while something is actually missing (silent once you're set up).

let
  # Cheap, tool-free checks reused by both the command and the activation hint.
  # (File-existence only, so they're safe to run during activation where PATH
  # is restricted.)
  checkGitIdentity = ''[ -f "$HOME/.config/git/identity-personal" ] && [ -f "$HOME/.config/git/identity-work" ]'';
  checkCredStore = ''[ -f "$HOME/.password-store/.gpg-id" ]'';
  # Native-X steps only matter on profiles that manage ~/.xinitrc.
  checkNativeX = ''! { [ -f "$HOME/.xinitrc" ] && [ ! -x /usr/bin/i3lock ]; }'';

  setup-status = pkgs.writeShellScriptBin "setup-status" ''
    pending=0
    ok()   { printf '  [ ok ]  %s\n' "$1"; }
    todo() { printf '  [TODO]  %s\n          -> run: %s\n' "$1" "$2"; pending=$((pending + 1)); }

    echo
    echo "First-time setup status"
    echo "======================="

    # 1. Git identity (per-directory name/email)
    if ${checkGitIdentity}; then
      ok "Git identity            (~/.config/git/identity-personal, -work)"
    else
      todo "Git identity            (name/email per directory)" "git-identity-setup"
    fi

    # 2. Git credential store (passphraseless gpg key + pass). This one also
    #    verifies the key actually exists, not just that .gpg-id is present.
    if ${checkCredStore} \
       && ${pkgs.gnupg}/bin/gpg --list-secret-keys "$(cat "$HOME/.password-store/.gpg-id")" >/dev/null 2>&1; then
      ok "Git credential store    (gpg key + pass)"
    else
      todo "Git credential store    (passphraseless gpg key + pass)" "gcm-setup"
    fi

    # 3. Native X + screen lock (only shown on native-X profiles)
    if [ -f "$HOME/.xinitrc" ]; then
      if [ -x /usr/bin/i3lock ] && [ -f /etc/pam.d/i3lock ]; then
        ok "Native X + screen lock  (xorg, i3lock, PAM)"
      else
        todo "Native X + screen lock  (xorg/xinit/i3lock via apt)" "x11-setup"
      fi
    fi

    echo
    if [ "$pending" -eq 0 ]; then
      echo "  All set - nothing left to do."
    else
      echo "  $pending step(s) pending - run the command(s) above."
    fi
    echo
  '';
in
{
  home.packages = [ setup-status ];

  # Login hint (MOTD-style): while any step is pending, print one line on each
  # new interactive shell, then self-silence once setup is complete. Uses cheap
  # file checks only (no gpg) to keep shell startup fast. Turn it off anytime
  # with `export DOTFILES_SETUP_HINT_OFF=1`.
  programs.zsh.initContent = lib.mkAfter ''
    if [[ -o interactive && -z "''${DOTFILES_SETUP_HINT_OFF:-}" ]]; then
      if ! { ${checkGitIdentity} && ${checkCredStore} && ${checkNativeX} ; }; then
        print -P "%F{yellow}⚠ first-time setup pending — run 'setup-status'%f"
      fi
    fi
  '';

  # Build-time hint: after `home-manager switch`, list any pending steps.
  # Prints nothing once everything is done, so it never becomes noise.
  home.activation.setupStatusHint = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    _pending=""
    ${checkGitIdentity} || _pending="$_pending git-identity-setup"
    ${checkCredStore}    || _pending="$_pending gcm-setup"
    ${checkNativeX}      || _pending="$_pending x11-setup"
    if [ -n "$_pending" ]; then
      echo ""
      echo "  first-time setup pending ->$_pending"
      echo "  run 'setup-status' for details."
      echo ""
    fi
  '';
}
