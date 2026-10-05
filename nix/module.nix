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
        ExecStart = "${cfg.package}/bin/bobert";
        Restart = "on-failure";
        DynamicUser = true;
      };
    };
  };
}