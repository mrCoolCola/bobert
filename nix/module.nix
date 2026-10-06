{ config, lib, pkgs, ... }:

let
  cfg = config.services.bobert;
in
{
  options.services.bobert = {
    enable = lib.mkEnableOption "My Rust telegram bot";
    package = lib.mkOption {
      type = lib.types.package;
      description = "The bobert package to use.";
    };
    token = lib.mkOption {
      type = lib.types.str;
      default = "placeholder";
      description = "Telegram token of the bot";
    };
    users = lib.mkOption {
      type = lib.types.listOf lib.types.ints.positive;
      default = [ ];
      description = "List of Telegram ids of users";
    };
    nicknames = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "List of nicknames of users";
    };
    report = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable daily bobert-report";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.bobert = {
      description = "My Rust telegram bot";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" "tor.service" ];
      environment = {
        BOBERT_TOKEN = cfg.token;
        BOBERT_USERS = lib.concatMapStringsSep "," toString cfg.users;
        BOBERT_NICKNAMES = lib.concatMapStringsSep "," toString cfg.nicknames;
      };
      serviceConfig = {
        ExecStart = "${cfg.package}/bin/bobert start";
        Restart = "on-failure";
        DynamicUser = true;
      };
    };
    systemd.services.bobert-report = {
      description = "System statistic report";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" "tor.service" ];
      environment = {
        BOBERT_TOKEN = cfg.token;
        BOBERT_USERS = lib.concatMapStringsSep "," toString cfg.users;
        BOBERT_NICKNAMES = lib.concatMapStringsSep "," toString cfg.nicknames;
      };
      serviceConfig = {
        ExecStart = "${cfg.package}/bin/bobert report";
        RemainAfterExit = true; # Prevents the service from automatically starting on rebuild.
        Type = "oneshot";
        DynamicUser = true;
      };
    };
    systemd.timers."bobert-report" = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "*-*-* 15:00:00";
        Unit = "bobert-report.service";
      };
    };
  };
}