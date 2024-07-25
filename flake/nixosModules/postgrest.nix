{...}: {
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
      systemd.services.postgrest = {
        wantedBy = ["multi-user.target"];
        after = ["postgresql.service"];

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
