{
  config,
  pkgs,
  lib,
  ...
}:

let
  home-packages = config.home-manager.users.${config.user}.home.packages;
in
{

  options = {
    gitName = lib.mkOption {
      type = lib.types.str;
      description = "Name to use for git commits";
    };
    gitEmail = lib.mkOption {
      type = lib.types.str;
      description = "Email to use for git commits";
    };
  };

  config = {

    home-manager.users.root.programs.git = {
      enable = true;
      extraConfig.safe.directory = config.dotfilesPath;
    };

    home-manager.users.${config.user} = {
      programs.git = {
        enable = true;
        userName = config.gitName;
        userEmail = config.gitEmail;
        extraConfig = {
          core.pager = "${pkgs.git}/share/git/contrib/diff-highlight/diff-highlight | less -F";
          interactive.difffilter = "${pkgs.git}/share/git/contrib/diff-highlight/diff-highlight";
          pager = {
            branch = "false";
          };
          safe = {
            directory = config.dotfilesPath;
          };
          pull = {
            ff = "only";
          };
          push = {
            autoSetupRemote = "true";
          };
          init = {
            defaultBranch = "master";
          };
          rebase = {
            autosquash = "true";
          };
          gpg = {
            format = "ssh";
            ssh.allowedSignersFile = "~/.config/git/allowed-signers";
          };
          # commit.gpgsign = true;
          # tag.gpgsign = true;
        };
        ignores = [
          ".direnv/**"
          "result"
        ];
        includes = [
          {
            path = "~/.config/git/personal";
            condition = "gitdir:~/dev/personal/";
          }
        ];
      };

      # Personal git config
      # TODO: fix with variables
      xdg.configFile."git/personal".text = ''
        [user]
            name = "${config.fullName}"
            email = "PLACEHOLDER@users.noreply.github.com"
            signingkey = ~/.ssh/id_ed25519
        [commit]
            gpgsign = true
        [tag]
            gpgsign = true
      '';

      xdg.configFile."git/allowed-signers".text = ''
        PLACEHOLDER@users.noreply.github.com ssh-ed25519 PLACEHOLDER_KEY
      '';

      home.packages = with pkgs; [
        zsh
        fzf
        bat
      ];
    };
  };
}
