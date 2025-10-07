{ config, pkgs, lib, ... }:
{

  options.clojure.enable = lib.mkEnableOption "Clojure programming language.";

  config = lib.mkIf config.clojure.enable {
      home.packages = with pkgs; [
        fira-code-symbols
        jdk17
        clojure
        leiningen
        babashka
        clojure-lsp
        cider
        clj-kondo
       #emacsPackages.mu4e
       #emacsPackages.ob-clojurescript
       #emacsPackages.flycheck-clojure
       #emacsPackages.clojure-ts-mode
       #emacsPackages.clojure-mode
      ];
  };
}

