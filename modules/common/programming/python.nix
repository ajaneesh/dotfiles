{
  config,
  pkgs,
  lib,
  ...
}:
let 
  lib_deps = with pkgs; [
        stdenv.cc.cc.lib
        zlib
        libGL
        libGLU
        glib
        glibc
        libgcc
  ];
in
{

  options.python.enable = lib.mkEnableOption "Python programming language.";

  config = lib.mkIf config.python.enable {

    environment.sessionVariables = {
      LD_LIBRARY_PATH = "${lib.makeLibraryPath lib_deps}";
    };
    
    home-manager.users.${config.user} = {

      home.packages = with pkgs; [
        libffi
        openssl
        gcc
        cmake
        extra-cmake-modules
        gnumake
        poetry
        imagemagick
        postgresql_15
        pyright
        python310
        # python3Packages.behave
        # python3Packages.coverage
        # python3Packages.debugpy
        # python3Packages.pytest
        # python3Packages.pytest-bdd
        # python3Packages.pytest-cov
        # python3Packages.reformat-gherkin

        # commented out to solve problems with billuminati
        # python3Packages.black
        # python3Packages.flake8
        # python3Packages.isort
        # python3Packages.mypy
        # python3Packages.pylint
        # python3Packages.pylsp-mypy
        # python3Packages.pytest-xdist
        # python3Packages.pytest-xdist
        # python3Packages.python-lsp-black
        # python3Packages.python-lsp-ruff
        # python3Packages.python-lsp-server
        # python3Packages.tabulate 
      ] ++ lib_deps;

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
