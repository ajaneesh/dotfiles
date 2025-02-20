# modules/common/applications/email.nix
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.email-manager;
in {
  options.email-manager = {
    enable = mkEnableOption "email management";
    
    gmail = {
      enable = mkEnableOption "Gmail account management";
      address = mkOption {
        type = types.str;
        description = "Gmail email address";
      };
      realName = mkOption {
        type = types.str;
        description = "Real name to use for the email account";
      };
    };
  };

  config = mkIf cfg.enable {
    home-manager.users.${config.user} = { ... }: {
      programs = {
        mbsync.enable = true;
        msmtp.enable = true;
      };

      accounts.email = {
        maildirBasePath = "Mail";
        accounts.gmail = mkIf cfg.gmail.enable {
          primary = true;
          address = cfg.gmail.address;
          realName = cfg.gmail.realName;
          userName = cfg.gmail.address;
          passwordCommand = "age-decrypt /home/${config.user}/.config/age/secrets/gmail-password.age";
          
          imap = {
            host = "imap.gmail.com";
            port = 993;
            tls.enable = true;
          };

          smtp = {
            host = "smtp.gmail.com";
            port = 587;
            tls.enable = true;
          };

          mbsync = {
            enable = true;
            create = "maildir";
          };

          msmtp.enable = true;
        };
      };
    };
  };
}
