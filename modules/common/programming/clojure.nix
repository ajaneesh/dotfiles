{ config, pkgs, lib, ... }:
{

  options.clojure.enable = lib.mkEnableOption "Clojure programming language.";

  config = lib.mkIf config.clojure.enable {

    home-manager.users.${config.user} = {

      home.packages = with pkgs; [
        fira-code-symbols
        nodejs_22
        jdk17
        clojure
        leiningen
        babashka
        clojure-lsp
        cider
        emacsPackages.ob-clojurescript
        emacsPackages.flycheck-clojure
        emacsPackages.clojure-ts-mode
        emacsPackages.clojure-mode
      ];

    };
  };
}
