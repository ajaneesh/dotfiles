{ config, pkgs, lib, ... }:
{

  options.docker.enable = lib.mkEnableOption "Docker Compose Support";

  config = lib.mkIf config.docker.enable {

    home.sessionVariables = {
        DOCKER_CONFIG = "${config.home.homeDirectory}/.docker";
    };

    home.packages = with pkgs; [
      docker-compose
      docker
      docker-credential-helpers
      pass
      gnupg
    ];

    home.file.".docker/config.json".text = ''
{
      "credsStore": "pass"
}
'';

  };
}