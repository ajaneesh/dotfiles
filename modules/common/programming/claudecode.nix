{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.claudecode;
in
{
  options.claudecode = {
    enable = lib.mkEnableOption "Claude Code AI coding assistant";
  };

  config = lib.mkIf cfg.enable {
    # Install the official claude-code package from nixpkgs
    home-manager.users.${config.user} = {
      home.packages = [
        pkgs.claude-code
        # Create a claude-code wrapper script for Emacs integration
        (pkgs.writeShellScriptBin "claude-code" ''
          exec ${pkgs.claude-code}/bin/claude "$@"
        '')
      ];

      # Simple zsh aliases
      # home.shellAliases = lib.mkIf config.zsh.enable {
      #   cc = "claude-code";
      #   ccf = "claude-code --files";
      # };
    };
  };
}
