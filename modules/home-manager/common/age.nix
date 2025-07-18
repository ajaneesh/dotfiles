# /home/nixos/dotfiles/modules/home-manager/common/age.nix
{ config, lib, pkgs, ... }:

let
  # Define the secrets needed based on enabled applications
  requiredSecrets = {
    git-name = {
      description = "Git commit name (e.g., 'John Doe')";
      condition = true; # Always needed since git is always enabled
      path = "git/name";
    };
    git-email = {
      description = "Git commit email (e.g., 'john@example.com')";
      condition = true; # Always needed since git is always enabled
      path = "git/email";
    };
    github-token = {
      description = "GitHub personal access token (for git push/pull)";
      condition = true; # Always needed for GitHub operations
      path = "github/token";
    };
    ssh-key = {
      description = "SSH private key for git signing";
      condition = true;
      path = "ssh/private-key";
    };
  };

  # Filter to only include secrets for enabled applications
  enabledSecrets = lib.filterAttrs (name: secret: secret.condition) requiredSecrets;

  # Generate the configuration script body
  generateConfigureScript = lib.concatMapStrings (secretName:
    let
      secret = enabledSecrets.${secretName};
      secretFile = "${config.xdg.configHome}/age/secrets/${secret.path}.age";
    in
    ''
      echo ""
      echo "=== ${secretName} ==="
      echo "📝 ${secret.description}"
      echo "📁 Will be stored at: ${secretFile}"
      
      if [ -f "${secretFile}" ]; then
        echo "✅ Secret already exists."
        read -p "   Update it? [y/N] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
          configure_secret "${secretName}" "${secretFile}" "${secret.description}"
        fi
      else
        echo "❌ Secret is missing."
        read -p "   Configure it now? [Y/n] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
          configure_secret "${secretName}" "${secretFile}" "${secret.description}"
        fi
      fi
    '') (lib.attrNames enabledSecrets);

  # Create custom packages for age utilities
  age-init = pkgs.writeShellScriptBin "age-init" ''
    if [[ ! -f ~/.config/age/keys.txt ]]; then
      echo "Generating new age key pair..."
      mkdir -p ~/.config/age
      ${pkgs.age}/bin/age-keygen -o ~/.config/age/keys.txt
      chmod 600 ~/.config/age/keys.txt
    fi
  '';

  age-encrypt = pkgs.writeShellScriptBin "age-encrypt" ''
    if [[ ! -f ~/.config/age/keys.txt ]]; then
      echo "No age keys found. Run age-init first."
      exit 1
    fi
    
    PUBLIC_KEY=$(grep "public key:" ~/.config/age/keys.txt | cut -d: -f2 | tr -d ' ')
    
    if [ "$#" -lt 1 ]; then
      echo "Usage: age-encrypt <output-file.age>"
      echo "Reads from stdin and encrypts to specified file"
      exit 1
    fi
    
    # Ensure directory exists
    mkdir -p "$(dirname "$1")"
    
    ${pkgs.age}/bin/age -r "$PUBLIC_KEY" > "$1"
    echo "Encrypted to $1"
  '';

  age-decrypt = pkgs.writeShellScriptBin "age-decrypt" ''
    if [[ ! -f ~/.config/age/keys.txt ]]; then
      echo "No age keys found. Run age-init first."
      exit 1
    fi
    
    if [ "$#" -ne 1 ]; then
      echo "Usage: age-decrypt <file.age>"
      exit 1
    fi
    
    ${pkgs.age}/bin/age -d -i ~/.config/age/keys.txt "$1"
  '';

  # Create a custom package for age-secrets-configure
  age-secrets-configure = pkgs.writeShellScriptBin "age-secrets-configure" ''
    # Helper function to configure a single secret
    configure_secret() {
      local name="$1"
      local file="$2"
      local description="$3"
      
      # Create directory if it doesn't exist
      mkdir -p "$(dirname "$file")"
      
      echo "   💬 $description"
      read -p "   Enter value: " -r VALUE
      
      if [ -n "$VALUE" ]; then
        # Initialize age keys if they don't exist
        if [[ ! -f ~/.config/age/keys.txt ]]; then
          echo "   🔑 Initializing age keys..."
          ${age-init}/bin/age-init
        fi
        
        # Use age-encrypt to encrypt the secret
        echo -n "$VALUE" | ${age-encrypt}/bin/age-encrypt "$file"
        echo "   ✅ Secret '$name' saved to $file"
      else
        echo "   ⏩ Skipped (no value entered)"
      fi
    }
    
    echo "🔐 Age Secrets Configuration"
    echo "============================"
    echo ""
    echo "This script will help you configure all secrets needed by your applications."
    echo "Secrets are encrypted using age and stored securely in ~/.config/age/secrets/"
    echo ""
    
    # Initialize age keys if needed
    if [[ ! -f ~/.config/age/keys.txt ]]; then
      echo "🔑 No age keys found. Creating new keypair..."
      ${pkgs.age}/bin/age-keygen -o ~/.config/age/keys.txt
      chmod 600 ~/.config/age/keys.txt
      echo ""
    fi
    
    ${generateConfigureScript}
    
    echo ""
    echo "🎉 Secret configuration complete!"
    echo ""
    echo "Next steps:"
    echo "- Rebuild your home-manager configuration to use the secrets"
    echo "- Run 'age-secrets-configure' anytime to update your secrets"
    echo ""
  '';

  # Create a custom package for age-get-secret
  age-get-secret = pkgs.writeShellScriptBin "age-get-secret" ''
    if [ "$#" -ne 1 ]; then
      echo "Usage: age-get-secret <secret-name>"
      echo "Available secrets: ${lib.concatStringsSep ", " (lib.attrNames enabledSecrets)}"
      exit 1
    fi
    
    SECRET_NAME="$1"
    case "$SECRET_NAME" in
      ${lib.concatMapStrings (name: 
        let secret = enabledSecrets.${name}; in
        ''
          ${name})
            ${pkgs.age}/bin/age -d -i ~/.config/age/keys.txt ~/.config/age/secrets/${secret.path}.age 2>/dev/null || echo ""
            ;;
        ''
      ) (lib.attrNames enabledSecrets)}
      *)
        echo "Unknown secret: $SECRET_NAME" >&2
        exit 1
        ;;
    esac
  '';

in
{
  home.packages = with pkgs; [
    age
    age-plugin-yubikey
    age-secrets-configure
    age-get-secret
    age-init
    age-encrypt
    age-decrypt
  ];

  # Create age directory structure
  xdg.configFile."age/.keep".text = "";

  # Create shell aliases
  programs.bash = {
    enable = true;
    shellAliases = {
      age-ls = "ls -l ~/.config/age";
      age-cat = "age-decrypt";
    };
  };

  # Add a home-manager activation script to ensure age is initialized and create git config
  home.activation.setupAge = lib.hm.dag.entryAfter ["installPackages"] ''
    $DRY_RUN_CMD $HOME/.nix-profile/bin/age-init
    
    # Create a git config file with secrets if they exist
    if [ -f ~/.config/age/secrets/git/name.age ] && [ -f ~/.config/age/secrets/git/email.age ]; then
      GIT_NAME=$(${age-get-secret}/bin/age-get-secret git-name 2>/dev/null || echo "")
      GIT_EMAIL=$(${age-get-secret}/bin/age-get-secret git-email 2>/dev/null || echo "")
      GITHUB_TOKEN=$(${age-get-secret}/bin/age-get-secret github-token 2>/dev/null || echo "")
      
      if [ -n "$GIT_NAME" ] && [ -n "$GIT_EMAIL" ]; then
        mkdir -p ~/.config/git
        cat > ~/.config/git/secrets <<EOF
[user]
    name = $GIT_NAME
    email = $GIT_EMAIL
EOF
        
        # Add GitHub token authentication if available
        if [ -n "$GITHUB_TOKEN" ]; then
          cat >> ~/.config/git/secrets <<EOF
[credential "https://github.com"]
    helper = !echo "username=token"; echo "password=$GITHUB_TOKEN"
EOF
        fi
      fi
    fi
  '';

  # Configure git to include the secrets file if it exists
  programs.git.includes = [
    {
      path = "~/.config/git/secrets";
      condition = null;
    }
  ];
}
