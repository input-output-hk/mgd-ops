{self, ...}: {
  flake.nixosModules.wireguard = {
    name,
    lib,
    config,
    nodes,
    ...
  }: {
    age.secrets.wg.file = "${self}/secrets/nodes/${name}/wg_priv.age";

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
          privateKeyFile = config.age.secrets.wg.path;
          ips = ["${wgIp name}/32"];
          listenPort = 51820;

          peers = lib.mapAttrsToList (nodeName: node: {
            name = nodeName;
            allowedIPs = ["${wgIp nodeName}/32"];
            endpoint = "${node.config.deployment.targetHost}:${toString node.config.networking.wireguard.interfaces.wg0.listenPort}";
            publicKey = lib.fileContents "${self}/flake/colmena/nodes/${nodeName}/wg_pub.key";
            persistentKeepalive = 25;
          }) (removeAttrs nodes [name]);
        };
      };
    };
  };
}
