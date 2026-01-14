{ config, pkgs, lib, ... }:

{
  options = {
    dunst.enable = lib.mkEnableOption "dunst notification daemon";
  };

  config = lib.mkIf config.dunst.enable {
    home.packages = with pkgs; [
      dunst
      libnotify
    ];

    # Configure dunst for notifications
    home.file.".config/dunst/dunstrc".text = ''
      [global]
          font = JetBrains Mono 9
          markup = yes
          format = "<b>%s</b>\n%b"
          sort = yes
          indicate_hidden = yes
          alignment = left
          show_age_threshold = 60
          word_wrap = yes
          ignore_newline = no
          width = 300
          height = (0, 300)
          origin = top-right
          offset = (30, 50)
          transparency = 10
          idle_threshold = 120
          monitor = 0
          follow = none
          sticky_history = yes
          force_xinerama = false
          history_length = 20
          line_height = 0
          separator_height = 2
          padding = 8
          horizontal_padding = 8
          separator_color = frame
          dmenu = ${pkgs.dmenu}/bin/dmenu -p dunst:
          browser = ${pkgs.firefox}/bin/firefox -new-tab
          icon_position = left
          max_icon_size = 32

      [urgency_low]
          background = "#222222"
          foreground = "#888888"
          timeout = 5

      [urgency_normal]
          background = "#285577"
          foreground = "#ffffff"
          timeout = 10

      [urgency_critical]
          background = "#900000"
          foreground = "#ffffff"
          timeout = 0
    '';
  };
}
