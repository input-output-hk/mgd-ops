{
  self,
  moduleWithSystem,
  ...
}: {
  flake.nixosModules.nomad-server = moduleWithSystem ({self'}: {
    lib,
    config,
    pkgs,
    name,
    nodes,
    ...
  }: {
    aws.instance.tags.Nomad = "cardano-perf-server";

    services.nomad = {
      enable = true;
      enableDocker = false;
      package = self'.packages.nomad;
      extraPackages = [pkgs.cni-plugins pkgs.nix];

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

        ui = {
          enabled = true;

          label.text = "Cardano Performance";
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
