{
  config,
  pkgs,
  lib,
  ...
}:
{

  options.vscode.enable = lib.mkEnableOption "Python VS Code IDE.";

  config = lib.mkIf config.vscode.enable {

    unfreePackages = [ "vscode" "vscode-extension-github-copilot-chat" "vscode-extension-github-copilot" ];

    home-manager.users.${config.user} = {

      home.packages = with pkgs; [
      ];

      programs.vscode = {
        enable = true;
	extensions = with pkgs.vscode-extensions; [
          bbenoist.nix
          github.copilot-chat
          github.copilot
        ];
      };
    };

  };

}


