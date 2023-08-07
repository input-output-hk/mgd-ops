{inputs, ...} @ parts: {
  perSystem = {
    pkgs,
    system,
    lib,
    config,
    ...
  }:
    lib.optionalAttrs (system == "x86_64-linux") {
      checks.test = inputs.nixpkgs.lib.nixos.runTest ({nodes, ...}: let
        inherit (parts.config.flake.nixosModules) common nomad-server nomad-client;

        snakeoil-keys = import "${inputs.nixpkgs}/nixos/tests/wireguard/snakeoil-keys.nix";
      in {
        name = "test";

        hostPkgs = pkgs;

        defaults = {lib, ...}: {
          imports = [common];

          networking.wireguard.enable = lib.mkForce false;
        };

        nodes = {
          leader = {...}: {
            imports = [nomad-server];
            systemd.services."serial-getty@ttyS0".enable = lib.mkForce false;
            networking.firewall.allowedTCPPorts = [];
            networking.wireguard.interfaces.wg0 = {
              privateKeyFile = snakeoil-keys.peer1;
              ips = ["100.0.0.1/32"];
            };
          };

          client = {
            imports = [nomad-client];
            networking.firewall.allowedTCPPorts = [];
            networking.wireguard.interfaces.wg0.privateKeyFile = snakeoil-keys.peer1;
            sops.secrets = lib.mkForce {};
            programs.auth-keys-hub.enable = lib.mkForce false;
            aws.region = "eu-central-1";
            systemd.services."serial-getty@ttyS0".enable = lib.mkForce false;
          };
        };

        testScript = ''
          start_all()

          leader.wait_for_unit("nomad.service")
          client.wait_for_unit("nomad.service")
        '';
      });
    };
}
