{inputs, ...}: {
  flake.nixosModules.postgrest = {
    lib,
    pkgs,
    config,
    ...
  }: let
    cfg = config.services.postgrest;
  in {
    options.services.postgrest = {
      enable = lib.mkEnableOption "PostgREST";

      dbuser = lib.mkOption {
        type = lib.types.str;
      };

      dbname = lib.mkOption {
        type = lib.types.str;
      };
    };

    config = lib.mkIf cfg.enable {
      systemd.services.sqitch-deploy = {
        wantedBy = ["multi-user.target"];
        after = ["postgresql.service"];

        environment = {
          SQITCH_USER_CONFIG = builtins.toFile "sqitch.conf" ''
            [user]
              name = mce-indexer
              email = mce-indexer@example.com
          '';
          TZ = "Etc/UTC";
        };

        path = [config.services.postgresql.package];

        serviceConfig = {
          WorkingDirectory = inputs.mgdoc-claim-enablement + /indexer;
          ExecStart = ''${lib.getExe pkgs.sqitchPg} deploy db:pg:///${cfg.dbuser}'';
          User = "postgres";
        };
      };

      systemd.services.postgrest = {
        wantedBy = ["multi-user.target"];
        after = ["postgresql.service" "sqitch-deploy.service"];

        environment = {
          PGUSER = cfg.dbuser;
          PGDATABASE = cfg.dbname;
        };

        serviceConfig = {
          ExecStart = "${lib.getExe pkgs.postgrest}";
        };
      };
    };
  };
}
