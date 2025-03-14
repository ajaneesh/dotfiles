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
        libffi
        openssl
        stdenv.cc.cc.lib
        zlib
        gcc
        gnumake
        poetry
        imagemagick
        pyright
        python3
        # python3Packages.behave
        python3Packages.black
        # python3Packages.coverage
        # python3Packages.debugpy
        python3Packages.flake8
        python3Packages.isort
        python3Packages.mypy
        python3Packages.numpy
        python3Packages.pandas
        python3Packages.pylint
        python3Packages.pylsp-mypy
        # python3Packages.pytest
        # python3Packages.pytest-bdd
        # python3Packages.pytest-cov
        python3Packages.pytest-xdist
        python3Packages.pytest-xdist
        python3Packages.python-lsp-black
        python3Packages.python-lsp-ruff
        python3Packages.python-lsp-server
        # python3Packages.reformat-gherkin
        python3Packages.tabulate 
      ];

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
