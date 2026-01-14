self: super: {
  # Override i3lock to ensure PAM is enabled and provide a wrapper
  # that works with Debian's PAM configuration
  i3lock-debian = super.writeShellScriptBin "i3lock" ''
    # Use system i3lock if available (has setuid permissions)
    # Otherwise fall back to Nix i3lock
    if [ -x /usr/bin/i3lock ]; then
      exec /usr/bin/i3lock "$@"
    else
      echo "ERROR: i3lock requires system installation on Debian for PAM authentication"
      echo "Please run: sudo apt install i3lock"
      exit 1
    fi
  '';
}
