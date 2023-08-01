{self, ...}: {
  flake.nixosModules.wireguard = {
    name,
    lib,
    config,
    nodes,
    ...
  }: {
    sops.secrets.wg = {
      sopsFile = "${self}/secrets/wg_private_${name}";
      format = "binary";
    };

    networking = {
      nat = {
        enable = true;
        externalInterface = "eth0";
        internalInterfaces = ["wg0"];
      };

      firewall = {
        allowedUDPPorts = [config.networking.wireguard.interfaces.wg0.listenPort];
        interfaces.wg0.allowedTCPPorts = [9598]; # vector
      };

      wireguard = {
        enable = true;

        interfaces.wg0 = let
          wgIp = name: "10.200.0." + lib.removePrefix "ci" name;
        in {
          privateKeyFile = config.sops.secrets.wg.path;
          ips = ["${wgIp name}/32"];
          listenPort = 51820;

          peers = lib.mapAttrsToList (nodeName: node: {
            name = nodeName;
            allowedIPs = ["${wgIp nodeName}/32"];
            endpoint = "${node.config.deployment.targetHost}:${toString node.config.networking.wireguard.interfaces.wg0.listenPort}";
            publicKey = lib.fileContents "${self}/secrets/wg_public_${nodeName}";
            persistentKeepalive = 25;
          }) (removeAttrs nodes [name]);
        };
      };
    };
  };
}
