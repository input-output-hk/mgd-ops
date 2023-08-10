{moduleWithSystem, ...}: {
  flake.nixosModules.nomad-server = moduleWithSystem ({self'}: {
    lib,
    config,
    pkgs,
    ...
  }: {
    aws.instance.tags.Role = "cardano-perf-server";

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

        limits = {
          http_max_conns_per_client = 200;
          rpc_max_conns_per_client = 200;
        };
      };
    };
  });
}
