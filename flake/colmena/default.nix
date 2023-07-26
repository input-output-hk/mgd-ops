{
  inputs,
  config,
  ...
}: let
  inherit (config.flake) nixosModules;
in {
  flake = {
    nixosConfigurations = (inputs.colmena.lib.makeHive config.flake.colmena).nodes;

    colmena = {
      meta.nixpkgs = import inputs.nixpkgs {
        system = "x86_64-linux";
      };

      defaults.imports = [nixosModules.common];

      perf1 = {
        imports = [./nodes/perf1 nixosModules.aws-t3a-medium nixosModules.nomad-master];
      };
    };
  };
}
