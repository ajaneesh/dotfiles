{ config, pkgs, lib, ... }:

{
  programs.git = {
    userName = "Your Name"; # Will be overridden by age secrets
    userEmail = "your.email@example.com"; # Will be overridden by age secrets
  };

  programs.zsh.shellAliases = {
    # Git aliases with age secrets
    git-commit = ''git -c user.name="$(age-get-secret git-name 2>/dev/null || echo 'Your Name')" -c user.email="$(age-get-secret git-email 2>/dev/null || echo 'your.email@example.com')" commit'';
    git-commit-signed = ''git -c user.name="$(age-get-secret git-name 2>/dev/null || echo 'Your Name')" -c user.email="$(age-get-secret git-email 2>/dev/null || echo 'your.email@example.com')" commit -S'';
  };

  home.packages = with pkgs; [
    git
  ];
}
