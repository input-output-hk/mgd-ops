{
  self,
  moduleWithSystem,
  ...
}: {
  flake.nixosModules.nomad-master = moduleWithSystem ({self'}: {
    lib,
    config,
    name,
    nodes,
    ...
  }: {
    deployment.tags = ["nomad-master"];
    aws.instance.tags.Nomad = "cardano-perf-master";

    services.nomad = {
      enable = true;
      enableDocker = false;
      package = self'.packages.nomad;
      settings = {
        advertise = {
          http = "10.200.0.1";
          rpc = "10.200.0.1";
          serf = "10.200.0.1";
        };
        server = {
          enabled = true;
          bootstrap_expect = 1;
        };
      };
    };

    networking.wireguard.interfaces.wg0 = {
      peers = lib.mapAttrsToList (nodeName: node: {
        name = nodeName;
        allowedIPs = node.config.networking.wireguard.interfaces.wg0.ips;
        publicKey = lib.fileContents "${self}/secrets/wireguard_${nodeName}.txt";
        persistentKeepalive = 25;
      }) (removeAttrs nodes [name]);
    };
  });
}
