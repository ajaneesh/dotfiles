{ config, pkgs, lib, ... }:

{
  options.aws = {
    enable = lib.mkEnableOption "AWS CLI tools";
    disableTests = lib.mkEnableOption "Disable tests for AWS CLI packages";
  };

  config = lib.mkIf config.aws.enable {
    home.packages =
      let
        awscli2 = if config.aws.disableTests
          then pkgs.awscli2.overridePythonAttrs (oldAttrs: { doCheck = false; })
          else pkgs.awscli2;
      in
      [ awscli2 ];
  };
}
