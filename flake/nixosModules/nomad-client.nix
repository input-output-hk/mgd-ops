{moduleWithSystem, ...}: {
  flake.nixosModules.nomad-client = moduleWithSystem ({self'}: {
    nodes,
    config,
    pkgs,
    lib,
    ...
  }: {
    aws.instance.tags.Role = "cardano-perf-client";

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
            retry_join = [(lib.removeSuffix "/32" (builtins.elemAt nodes.leader.config.networking.wireguard.interfaces.wg0.ips 0))];
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
  });
}
