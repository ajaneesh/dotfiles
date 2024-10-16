{
  config,
  pkgs,
  lib,
  ...
}:
{

  users.users.${config.user}.shell = pkgs.zsh;
  programs.zsh.enable = true; # Needed for LightDM to remember username

  home-manager.users.${config.user} = {

    # Packages used in abbreviations and aliases
    home.packages = with pkgs; [ curl ];

    programs.zsh = {
      enable = true;
      shellAliases = {

        # Use eza (exa) instead of ls for fancier output
        # ls = "${pkgs.eza}/bin/eza --group";

        # Move files to XDG trash on the commandline
        trash = lib.mkIf pkgs.stdenv.isLinux "${pkgs.trash-cli}/bin/trash-put";
      };
    };

    programs.starship.enableZshIntegration = true;
    programs.zoxide.enableZshIntegration = true;
    programs.fzf.enableZshIntegration = true;
  };
}
