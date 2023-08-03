{self, ...}: {
  flake.nixosModules.wireguard = {
    name,
    lib,
    config,
    nodes,
    ...
  }: {
    sops.secrets.wg.sopsFile = "${self}/secrets/wireguard_${name}.enc";

    systemd.services.wireguard-wg0 = {
      after = ["sops-nix.service"];
      serviceConfig.SupplementaryGroups = [config.users.groups.keys.name];
      # unitConfig.ConditionPathExists = config.sops.secrets.wg.path;
    };

    networking = {
      # nat = {
      #   enable = true;
      #   externalInterface = "ens5";
      #   internalInterfaces = ["wg0"];
      # };

      firewall = {
        allowedUDPPorts = [config.networking.wireguard.interfaces.wg0.listenPort];
        interfaces.wg0 = {
          allowedTCPPorts = [22 80 443 4646 4647];
          allowedUDPPorts = [4648];
        };
      };

      wireguard = {
        enable = true;

        interfaces.wg0 = {
          privateKeyFile = config.sops.secrets.wg.path;
          listenPort = 51820;
          peers = [
            {
              name = "fmaste";
              allowedIPs = ["10.200.100.1/32"];
              publicKey = "Kb5WEHzkEpHVgD5OasHT6XsmZknGraXH50XbQ8Qdcys=";
              persistentKeepalive = 25;
            }
          ];
        };
      };
    };
  };
}
