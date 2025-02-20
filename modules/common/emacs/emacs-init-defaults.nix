# A collection of "uncontroversial" configurations for selected packages.

{ pkgs, lib, config, ... }:

{
  programs.emacs.init.usePackage = {
    all-the-icons = { extraPackages = [ 
      pkgs.emacs-all-the-icons-fonts
    ]; };

    css-ts-mode = {
      mode = [ ''"\\.css\\'"'' ];
      init = ''
        (add-to-list 'major-mode-remap-alist '(css-mode . css-ts-mode))
      '';
    };

    dap-lldb = {
      config = ''
        (setq dap-lldb-debug-program "${pkgs.lldb}/bin/lldb-vscode")
      '';
    };

    deadgrep = {
      config = ''
        (setq deadgrep-executable "${pkgs.ripgrep}/bin/rg")
      '';
    };

    dockerfile-mode.mode = [ ''"Dockerfile\\'"'' ];

    dockerfile-ts-mode.mode = [ ''"Dockerfile\\'"'' ];

    emacsql-sqlite3 = {
      defer = lib.mkDefault true;
      config = ''
        (setq emacsql-sqlite3-executable "${pkgs.sqlite}/bin/sqlite3")
      '';
    };

    js-ts-mode = {
      mode = [ ''"\\.js\\'"'' ];
      init = ''
        (add-to-list 'major-mode-remap-alist '(js2-mode . js-ts-mode))
        (add-to-list 'major-mode-remap-alist '(js-mode . js-ts-mode))
        (add-to-list 'major-mode-remap-alist '(javascript-mode . js-ts-mode))
      '';
    };

    json-ts-mode = {
      mode = [ ''"\\.json\\'"'' ];
      init = ''
        (add-to-list 'major-mode-remap-alist '(js-json-mode . json-ts-mode))
      '';
    };

    lsp-eslint = {
      config = ''
        (setq lsp-eslint-server-command '("node" "${pkgs.vscode-extensions.dbaeumer.vscode-eslint}/share/vscode/extensions/dbaeumer.vscode-eslint/server/out/eslintServer.js" "--stdio"))
      '';
    };

    lsp-pylsp = {
      config = ''
        (setq lsp-pylsp-server-command
                "${lib.getExe pkgs.python3Packages.python-lsp-server}")
      '';
    };

    markdown-mode = {
      mode = [ ''"\\.mdwn\\'"'' ''"\\.markdown\\'"'' ''"\\.md\\'"'' ];
    };

    nix-mode.mode = [ ''"\\.nix\\'"'' ];

    notmuch = {
      package = epkgs: lib.getOutput "emacs" pkgs.notmuch;
      config = ''
        (setq notmuch-command "${pkgs.notmuch}/bin/notmuch")
      '';
    };

    octave.mode = [ ''("\\.m\\'" . octave-mode)'' ];

    ob-plantuml = {
      config = ''
        (setq org-plantuml-jar-path "${pkgs.plantuml}/lib/plantuml.jar")
      '';
    };

    org-roam = {
      defines = [ "org-roam-graph-executable" ];
      config = ''
        (setq org-roam-graph-executable "${pkgs.graphviz}/bin/dot")
      '';
    };

    protobuf-mode.mode = [ ''"\\.proto\\'"'' ];

    python-ts-mode = {
      mode = [ ''"\\.py\\'"'' ];
      init = ''
        (add-to-list 'major-mode-remap-alist '(python-mode . python-ts-mode))
      '';
    };

    ripgrep = {
      config = ''
        (setq ripgrep-executable "${pkgs.ripgrep}/bin/rg")
      '';
    };

    terraform-mode.mode = [ ''"\\.tf\\(vars\\)?\\'"'' ];

    toml-ts-mode = {
      mode = [ ''"\\.toml\\'"'' ];
      init = ''
        (add-to-list 'major-mode-remap-alist '(conf-toml-mode . toml-ts-mode))
      '';
    };

    tsx-ts-mode = {
      mode = [ ''"\\.[jt]sx\\'"'' ];
      init = ''
        (add-to-list 'major-mode-remap-alist '(js-jsx-mode . tsx-ts-mode))
      '';
    };

    yaml-mode.mode = [ ''"\\.\\(e?ya?\\|ra\\)ml\\'"'' ];

    yaml-ts-mode = {
      mode = [ ''"\\.\\(e?ya?\\|ra\\)ml\\'"'' ];
      init = ''
        (add-to-list 'major-mode-remap-alist '(yaml-mode . yaml-ts-mode))
      '';
    };
  };
}
