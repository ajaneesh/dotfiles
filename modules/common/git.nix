{ config, pkgs, lib, ... }:

{
  programs.git = {
    enable = true;
    settings.user.name = "Your Name"; # Will be overridden by age secrets
    settings.user.email = "your.email@example.com"; # Will be overridden by age secrets
  };

  programs.zsh.shellAliases = {
    # Git aliases with age secrets
    git-commit = ''git -c user.name="$(age-get-secret git-name 2>/dev/null || echo 'Your Name')" -c user.email="$(age-get-secret git-email 2>/dev/null || echo 'your.email@example.com')" commit'';
    git-commit-signed = ''git -c user.name="$(age-get-secret git-name 2>/dev/null || echo 'Your Name')" -c user.email="$(age-get-secret git-email 2>/dev/null || echo 'your.email@example.com')" commit -S'';
  };

  # Git Credential Manager with GPG credential store
  programs.git.settings = {
    credential.helper = "${pkgs.git-credential-manager}/bin/git-credential-manager";
    credential.credentialStore = "gpg";
    "credential.https://emu.hinagro.com".provider = "generic";
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

  # One-time setup script for GCM prerequisites
  home.packages = with pkgs; [
    git
    git-credential-manager
    openssh
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
