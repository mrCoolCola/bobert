{ config, lib, pkgs, ... }:let
  cfg = config.services.bobert;
in {
  options.services.bobert = {
    enable = lib.mkEnableOption "My Rust telegram bot";
    token = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Telegram token of the bot";
    };
    users = lib.mkOption {
      type = lib.types.listOf lib.types.ints.positive;
      default = [];
      description = "List of Telegram ids of users";
    };
    nicknames = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "List of nicknames of users";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.bobert = {
      description = "My Rust App";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" "tor.service" ];

      serviceConfig = {
        ExecStart = "${cfg.package}/bin/bobert --port ${toString cfg.port}";
        Restart = "on-failure";
        DynamicUser = true;
      };
    };
  };
}