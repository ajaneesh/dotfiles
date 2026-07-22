final: prev: {
  # nixpkgs (as of 2026-07) builds tree-sitter-tsx from the root of the
  # tree-sitter-typescript repo, so the resulting library exports
  # tree_sitter_typescript instead of tree_sitter_tsx and Emacs fails to
  # load the grammar. Rebuild it from the tsx/ subdirectory.
  #
  # tree-sitter-grammars is a makeScope set; overrideScope propagates the
  # fix into allGrammars, which emacsPackages.treesit-grammars consumes.
  tree-sitter-grammars = prev.tree-sitter-grammars.overrideScope (
    gfinal: gprev: {
      tree-sitter-tsx = prev.tree-sitter.buildGrammar {
        language = "tsx";
        inherit (gprev.tree-sitter-tsx) version src;
        location = "tsx";
      };
    }
  );
}
