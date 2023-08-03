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
      in {
        name = "test";

        hostPkgs = pkgs;

        defaults = {lib, ...}: {
          imports = [common];

          networking.wireguard.enable = lib.mkForce false;
        };

        nodes = {
          leader = {config, ...}: {
            imports = [nomad-server];
            networking.firewall.allowedTCPPorts = [];
          };

          client = {
            imports = [nomad-client];
            networking.firewall.allowedTCPPorts = [];
          };
        };

        testScript = ''
          leader.wait_for_unit("nomad.service")
          client.wait_for_unit("nomad.service")
        '';
      });
    };
}
