{
  config,
  pkgs,
  lib,
  ...
}:
{

  options.terraform.enable = lib.mkEnableOption "Terraform tools.";

  config = lib.mkIf config.terraform.enable {
    unfreePackages = [ "terraform" ];

    home-manager.users.${config.user} = {
      home.packages = with pkgs; [
        terraform # Terraform executable
        terraform-ls # Language server
        tflint # Linter
      ];
    };
  };
}
