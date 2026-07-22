{ config, pkgs, lib, ... }:

{
  programs.git = {
    enable = true;

    settings = {
      # No global identity. Refuse to commit unless one of the includes
      # below matches, so a wrong/placeholder identity can never leak
      # into history.
      user.useConfigOnly = true;

      # Git Credential Manager with GPG credential store
      credential.helper = "${pkgs.git-credential-manager}/bin/git-credential-manager";
      credential.credentialStore = "gpg";
    };

    # Identity files live outside this repo (untracked, per-machine).
    # Provision them with `git-identity-setup`.
    includes = [
      {
        condition = "gitdir:~/dotfiles/";
        path = "~/.config/git/identity-personal";
      }
      {
        condition = "gitdir:~/projects/";
        path = "~/.config/git/identity-work";
      }
    ];
  };

  # GPG
  programs.gpg.enable = true;

  services.gpg-agent = {
    enable = true;
    defaultCacheTtl = 86400;
    maxCacheTtl = 34560000;
    pinentry.package = pkgs.pinentry-tty;
    enableZshIntegration = true;
  };

  # Password store (used by GCM for credential storage)
  programs.password-store = {
    enable = true;
    settings = {
      PASSWORD_STORE_DIR = "$HOME/.password-store";
    };
  };

  home.packages = with pkgs; [
    git
    git-credential-manager
    openssh

    # One-time setup for the per-machine git identity files
    (writeShellScriptBin "git-identity-setup" ''
      set -e
      CONFIG_DIR="$HOME/.config/git"
      mkdir -p "$CONFIG_DIR"

      write_identity() {
        file="$1"
        label="$2"
        echo ""
        echo "=== $label ==="
        if [ -f "$file" ]; then
          echo "Current identity:"
          sed 's/^/  /' "$file"
          printf "Overwrite? [y/N] "
          read -r reply
          case "$reply" in
            [Yy]*) ;;
            *) echo "Keeping existing identity."; return 0 ;;
          esac
        fi
        printf "Name: "
        read -r name
        printf "Email: "
        read -r email
        printf '[user]\n\tname = %s\n\temail = %s\n' "$name" "$email" > "$file"
        chmod 600 "$file"
        echo "Wrote $file"
      }

      echo "=== Git Identity Setup ==="
      echo ""
      echo "Identities are stored locally under ~/.config/git/ and are"
      echo "never tracked by the dotfiles repo."
      echo ""
      echo "Tip: for the personal identity, use your GitHub noreply address"
      echo "(GitHub -> Settings -> Emails -> 'Keep my email addresses private',"
      echo "it looks like 12345678+username@users.noreply.github.com)."

      write_identity "$CONFIG_DIR/identity-personal" "Personal identity (~/dotfiles)"
      write_identity "$CONFIG_DIR/identity-work" "Work identity (~/projects)"

      echo ""
      echo "Done. Verify with:"
      echo "  cd ~/dotfiles && git config user.email"
      echo "  cd ~/projects/<repo> && git config user.email"
    '')

    # One-time setup script for GCM prerequisites
    (writeShellScriptBin "gcm-setup" ''
      set -e
      echo "=== Git Credential Manager Setup ==="
      echo ""

      # Ensure GPG_TTY is set
      export GPG_TTY=$(tty)

      # Step 1: GPG key
      KEY_ID=$(${pkgs.gnupg}/bin/gpg --list-keys --with-colons 2>/dev/null \
        | ${pkgs.gawk}/bin/awk -F: '/^pub/{getline; print $10; exit}')

      if [ -z "$KEY_ID" ]; then
        echo "No GPG key found. Generating one now..."
        echo ""
        ${pkgs.gnupg}/bin/gpg --gen-key
        KEY_ID=$(${pkgs.gnupg}/bin/gpg --list-keys --with-colons 2>/dev/null \
          | ${pkgs.gawk}/bin/awk -F: '/^pub/{getline; print $10; exit}')
      else
        echo "GPG key found: $KEY_ID"
      fi

      if [ -z "$KEY_ID" ]; then
        echo "ERROR: GPG key generation failed."
        exit 1
      fi

      # Step 2: Initialize password store
      if [ ! -f "$HOME/.password-store/.gpg-id" ]; then
        echo ""
        echo "Initializing password store..."
        ${pkgs.pass}/bin/pass init "$KEY_ID"
      else
        echo "Password store already initialized."
      fi

      # Step 3: Verify
      echo ""
      echo "=== Verification ==="
      echo "GPG key:          $KEY_ID"
      echo "Password store:   $HOME/.password-store"
      echo "Credential store: gpg"
      echo "Credential helper: git-credential-manager"
      echo ""
      echo "Setup complete. Git credentials will be stored securely via GPG."
    '')
  ];
}
