{self, ...}: {
  flake.nixosModules.nomad-client = {
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
      settings = {
        client = {
          enabled = true;
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
          endpoint = "3.72.83.208:51820";
          publicKey = lib.fileContents "${self}/secrets/wireguard_master.txt";
          persistentKeepalive = 25;
        }
      ];
    };
  };
}
