{
  self,
  moduleWithSystem,
  ...
} @ flake: {
  flake.nixosModules.nomad-client = moduleWithSystem ({self'}: {
    nodes,
    config,
    pkgs,
    lib,
    ...
  }: let
    leaderIps = nodes.leader.networking.wireguard.interfaces.wg0.ips;
    leaderIp = lib.removeSuffix "/32" (builtins.elemAt leaderIps 0);
  in {
    aws.instance.tags.Nomad = "cardano-perf-client";

    services.nomad = {
      enable = true;
      enableDocker = false;
      dropPrivileges = false;
      package = self'.packages.nomad;
      extraPackages = [pkgs.cni-plugins pkgs.nix];

      settings = {
        datacenter = config.aws.region;

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
