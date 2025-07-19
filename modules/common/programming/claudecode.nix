{ lib, pkgs, config, ... }:

let
  cfg = config.claudecode;
in
{
  options.claudecode = {
    enable = lib.mkEnableOption "Claude Code AI coding assistant";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.claude-code
      # The package executable is `claude`, this wrapper provides `claude-code`
      # for consistency and for tools that might expect it.
      (pkgs.writeShellScriptBin "claude-code" ''
        #!''${pkgs.stdenv.shell}
        exec "''${pkgs.claude-code}/bin/claude" "$@"
      '')
    ];

    # Add useful aliases for zsh
    programs.zsh.shellAliases = {
      cc = "claude-code";
      ccf = "claude-code --files";
    };
  };
}
