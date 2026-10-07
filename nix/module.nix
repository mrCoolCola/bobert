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
    tokenFile = lib.mkOption {
      type = lib.types.path;
      default = "";
      description = "Path to file with Telegram token of the bot";
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
    # подмодуль
    report = lib.mkOption {
      type = lib.types.submodule {
        options = {
          enable = lib.mkEnableOption "Ежедневный отчёт";
        };
      };
      default = {};
      description = "Настройки ежедневного отчёта";
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [{
      systemd.services.bobert = {
        description = "My Rust telegram bot";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" "tor.service" ];
        environment = {
          BOBERT_USERS = lib.concatMapStringsSep "," toString cfg.users;
          BOBERT_NICKNAMES = lib.concatMapStringsSep "," toString cfg.nicknames;
        } // lib.optionalAttrs (cfg.tokenFile == "") {
          BOBERT_TOKEN = cfg.token;
        } // lib.optionalAttrs (cfg.tokenFile != "") {
          BOBERT_TOKEN = "$(/run/current-system/sw/bin/cat ${cfg.tokenFile})";
        };
        serviceConfig = {
          ExecStart = "${cfg.package}/bin/bobert start";
          Restart = "on-failure";
          DynamicUser = true;
        };
      };
    }
    (lib.mkIf cfg.report.enable) {
      systemd.services.bobert-report = {
        description = "System statistic report";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" "tor.service" ];
        environment = lib.mkMerge [{
            BOBERT_USERS = lib.concatMapStringsSep "," toString cfg.users;
            BOBERT_NICKNAMES = lib.concatMapStringsSep "," toString cfg.nicknames;
          }
          (lib.mkIf (cfg.tokenFile == "") { # check if variable set
            BOBERT_TOKEN = cfg.token;
          })
        ];
        serviceConfig = {
          ExecStart = if cfg.tokenFile != "" then
            "${pkgs.bash}/bin/bash -c 'BOBERT_TOKEN=$(cat ${cfg.tokenFile}) ${cfg.package}/bin/bobert report'" # read file and set variable for bobert
          else
            "${cfg.package}/bin/bobert report";
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
    }
  ]);
}