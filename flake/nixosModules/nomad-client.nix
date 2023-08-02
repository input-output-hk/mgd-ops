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
  }: let
    leaderIps = nodes.leader.config.networking.wireguard.interfaces.wg0.ips;
    leaderIp = lib.removeSuffix "/32" (builtins.elemAt leaderIps 0);
  in {
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
          meta.perf = "true";
          node_class = "perf";

          server_join = {
            retry_join = [leaderIp];
            retry_max = 60;
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
          name = "leader";
          allowedIPs = leaderIps;
          endpoint = "leader.${flake.config.flake.cluster.domain}:51820";
          publicKey = lib.fileContents "${self}/secrets/wireguard_leader.txt";
          persistentKeepalive = 25;
        }
      ];
    };
  });
}
