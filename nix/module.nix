{ config, lib, pkgs, ... }:

let
  cfg = cfg;
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
    # report = lib.mkOption {
    #   type = lib.types.submodule {
    #     options = {
    #       enable = lib.mkEnableOption "Ежедневный отчёт";
    #     };
    #   };
    #   default = {};
    #   description = "Настройки ежедневного отчёта";
    # };
    report = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable daily bobert-report";
    };
    qbittorrentIntegration = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable messages about download done and started";
    };
  };
  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      systemd.services.bobert = {
        description = "My Rust telegram bot";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" "tor.service" ];
        environment = {
          BOBERT_USERS = lib.concatMapStringsSep "," toString cfg.users;
          BOBERT_NICKNAMES = lib.concatMapStringsSep "," toString cfg.nicknames;
        } // lib.optionalAttrs (cfg.tokenFile == "") {
          BOBERT_TOKEN = cfg.token;
        };
        serviceConfig = {
          ExecStart = if cfg.tokenFile != "" then
            "${pkgs.bash}/bin/bash -c 'BOBERT_TOKEN=$(cat ${cfg.tokenFile}) ${cfg.package}/bin/bobert start'"
          else
            "${cfg.package}/bin/bobert start";
          Restart = "on-failure";
          DynamicUser = true;
        };
      };
    }
    (lib.mkIf cfg.qbittorrentIntegration (
      let
        usersEnv     = "BOBERT_USERS=${lib.concatMapStringsSep "," toString cfg.users}";
        nicknamesEnv = "BOBERT_NICKNAMES=${lib.concatMapStringsSep "," toString cfg.nicknames}";
        tokenPrefix  =
          if cfg.tokenFile != "" then
            "BOBERT_TOKEN=$(cat ${cfg.tokenFile})"
          else
            "BOBERT_TOKEN=${cfg.token}";
        mkCmd = sub: "${tokenPrefix} ${usersEnv} ${nicknamesEnv} ${cfg.package}/bin/bobert ${sub} %N";
      in
      {
        services.qbittorrent.serverConfig.AutoRun = {
          enabled = true;
          program = mkCmd "qbit_done";
          OnTorrentAdded = {
            enabled = true;
            program = mkCmd "qbit_started";
          };
        };
      }
    ))
  ]);
}