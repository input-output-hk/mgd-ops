{
  self,
  moduleWithSystem,
  ...
} @ flake: {
  flake.nixosModules.nomad-client = moduleWithSystem ({self'}: {
    nodes,
    config,
    lib,
    ...
  }: {
    deployment.tags = ["nomad-client"];
    aws.instance.tags.Nomad = "cardano-perf-client";

    services.nomad = {
      enable = true;
      enableDocker = false;
      package = self'.packages.nomad;
      settings = {
        client = {
          enabled = true;
          network_interface = "wg0";
          server_join = {
            retry_join = ["10.200.0.1"];
            retry_max = 3;
            retry_interval = "15s";
          };
        };

        consul = {
          client_auto_join = false;
          auto_advertise = false;
        };
      };
    };

    networking.wireguard.interfaces.wg0 = {
      privateKeyFile = config.sops.secrets.wg.path;
      peers = [
        {
          name = "nomad-master";
          allowedIPs = ["10.200.0.1/32"];
          endpoint = "master.${flake.config.flake.cluster.domain}:51820";
          publicKey = lib.fileContents "${self}/secrets/wireguard_master.txt";
          persistentKeepalive = 25;
        }
      ];
    };
  });
}
