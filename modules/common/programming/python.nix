{
  config,
  pkgs,
  lib,
  ...
}:
{

  options.python.enable = lib.mkEnableOption "Python programming language.";

  config = lib.mkIf config.python.enable {

    home-manager.users.${config.user} = {

      home.packages = with pkgs; [
        python3
        # Build dependencies for tree-sitter
        gcc
        gnumake
    
        # Python LSP and development tools
        pyright
        python3Packages.python-lsp-server
        python3Packages.black
        python3Packages.isort
        python3Packages.debugpy
        # Additional LSP plugins
        python3Packages.pylsp-mypy
        python3Packages.python-lsp-black
        python3Packages.python-lsp-ruff
      ];

      # programs.fish.shellAbbrs = {
      #   py = "python3";
      # };

      # Optional: If you want to configure pyright globally
      home.file.".config/pyright/pyrightconfig.json".text = ''
            {
            "include": ["src"],
            "exclude": ["**/node_modules", "**/__pycache__"],
            "typeCheckingMode": "basic",
            "useLibraryCodeForTypes": true
            }
      '';
    };
  };
}
