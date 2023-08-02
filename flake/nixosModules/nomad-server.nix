{
  self,
  moduleWithSystem,
  ...
}: {
  flake.nixosModules.nomad-server = moduleWithSystem ({self'}: {
    lib,
    config,
    name,
    nodes,
    ...
  }: {
    deployment.tags = ["nomad-server"];
    aws.instance.tags.Nomad = "cardano-perf-server";

    services.nomad = {
      enable = true;
      enableDocker = false;
      package = self'.packages.nomad;

      settings = {
        advertise = let
          mask = builtins.elemAt config.networking.wireguard.interfaces.wg0.ips 0;
          ip = lib.removeSuffix "/32" mask;
        in {
          http = ip;
          rpc = ip;
          serf = ip;
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
