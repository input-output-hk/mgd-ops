{config, ...}: {
  flake.nixosModules.serve-runs = system: {
    sops.secrets.caddy-environment = {
      sopsFile = ../../secrets/caddy-environment.enc;
      restartUnits = ["caddy.service"];
    };

    systemd.services.caddy.serviceConfig = {
      EnvironmentFile =
        system.config.sops.secrets.caddy-environment.path;
      # ProtectHome = system.lib.mkForce false;
      BindReadOnlyPaths = "/home/dev/nomad-ssd/run:/var/lib/caddy/run";
    };

    services.caddy = {
      enable = true;
      email = "m.fellinger+cardano-perf-deployer@iohk.io";
      virtualHosts."deployer.${config.flake.cluster.domain}" = {
        extraConfig = ''
          encode zstd gzip
          basicauth { dev {$PASSWORD} }
          root * /var/lib/caddy/run
          file_server browse
        '';
      };
    };
  };
}
