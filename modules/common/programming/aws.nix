{ config, pkgs, lib, ... }:

{
  options.aws = {
    enable = lib.mkEnableOption "AWS CLI tools";
  };

  config = lib.mkIf config.aws.enable {
    home.packages = [ pkgs.awscli2 ];

    home.file.".aws/config".text = ''
      [cli]
      cli_auto_prompt = off
    '';
  };
}
