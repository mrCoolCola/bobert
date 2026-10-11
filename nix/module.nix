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
      type = lib.types.nullOr lib.types.str;
      default = "";
      description = "Telegram token of the bot";
    };
    tokenFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
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
        tokenEnv = if cfg.tokenFile != "" then
          "BOBERT_TOKEN=$(cat ${cfg.tokenFile})"
        else
          "BOBERT_TOKEN=${cfg.token}";
        # принимает первым аргументов действие qbit_done/qbit_started, 2-ым аргументом принимает сообщение
        msg_script = pkgs.writeShellScript "msg_script" ''
          ${tokenEnv} \
          BOBERT_USERS=${lib.concatMapStringsSep "," toString cfg.users} \
          BOBERT_NICKNAMES=${lib.concatMapStringsSep "," toString cfg.nicknames} \
          ${cfg.package}/bin/bobert $1 "$2" # именно так, и именно двойные кавычки
        '';
      in
      {
        services.qbittorrent.serverConfig = {
          AutoRun = {
            # в %N qbittorrent ложит название торрента
            enabled = true;
            program = "${msg_script} qbit_done '%N'";
            # case sensitive parameter names
            OnTorrentAdded.Enabled = true;
            OnTorrentAdded.Program = "${msg_script} qbit_started '%N'";
          };
          Preferences.WebUI.LocalHostAuth = false; # для того, чтоб боберт мог добавлять магнитки
        };
      }
    ))
  ]);
}