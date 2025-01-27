{ config, pkgs, lib, ... }:
{

  options.docker.enable = lib.mkEnableOption "Docker Compose Support";

  config = lib.mkIf config.docker.enable {

    environment.sessionVariables = {
        DOCKER_CONFIG = "/home/nixos/.docker";
    };

    home-manager.users.${config.user} = {

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
  };
}
