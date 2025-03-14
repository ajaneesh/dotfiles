{ config, pkgs, ... }:
{

  # FZF is a fuzzy-finder for the terminal

  home-manager.users.${config.user} = {

    programs.fzf.enable = true;

    # Global fzf configuration
    home.sessionVariables =
      let
        fzfCommand = "fd --type file";
      in
      {
        FZF_DEFAULT_COMMAND = fzfCommand;
        FZF_CTRL_T_COMMAND = fzfCommand;
        FZF_DEFAULT_OPTS = "-m --height 50% --border";
      };

    home.packages = [
      (pkgs.writeShellApplication {
        name = "jqr";
        runtimeInputs = [
          pkgs.jq
          pkgs.fzf
        ];
        text = builtins.readFile ./bash/scripts/jqr.sh;
      })
    ];
  };
}
