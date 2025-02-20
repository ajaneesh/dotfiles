# modules/common/applications/age.nix
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.age-manager;
in {
  options.age-manager = {
    enable = mkEnableOption "age secret management tools";
  };

  config = mkIf cfg.enable {
    home-manager.users.${config.user} = { config, lib, ... }: {  # Added config here
      home.packages = with pkgs; [
        age
        age-plugin-yubikey
      ];

      # Create age directory structure
      xdg.configFile."age/.keep".text = "";

      # Create helper scripts
      xdg.configFile."age/bin/age-init" = {
        executable = true;
        text = ''
          #!/usr/bin/env bash
          if [[ ! -f ~/.config/age/keys.txt ]]; then
            echo "Generating new age key pair..."
            ${pkgs.age}/bin/age-keygen -o ~/.config/age/keys.txt
            chmod 600 ~/.config/age/keys.txt
          fi
        '';
      };

      xdg.configFile."age/bin/age-encrypt" = {
        executable = true;
        text = ''
          #!/usr/bin/env bash
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
          
          age -r "$PUBLIC_KEY" > "$1"
          echo "Encrypted to $1 using key $PUBLIC_KEY"
        '';
      };

      xdg.configFile."age/bin/age-decrypt" = {
        executable = true;
        text = ''
          #!/usr/bin/env bash
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
      };

      # Add the scripts to PATH
      home.sessionPath = [ "${config.xdg.configHome}/age/bin" ];

      # Create shell aliases
      programs.bash = {
        enable = true;
        shellAliases = {
          age-ls = "ls ~/.config/age";
          age-cat = "age-decrypt";
        };
      };

      # Add a home-manager activation script to ensure age is initialized
      home.activation.setupAge = lib.hm.dag.entryAfter ["writeBoundary"] ''
        $DRY_RUN_CMD ${config.xdg.configHome}/age/bin/age-init
      '';
    };
  };
}
