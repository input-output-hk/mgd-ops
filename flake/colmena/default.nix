{
  inputs,
  config,
  lib,
  ...
}: let
  inherit (config.flake) nixosModules;
in {
  flake = {
    nixosConfigurations = (inputs.colmena.lib.makeHive config.flake.colmena).nodes;

    colmena = let
      mkNode = name: wgIp: imports: {
        "${name}" = {
          imports =
            [
              (volume 60)
              {
                networking.wireguard.interfaces.wg0.ips = ["${wgIp}/32"];
                deployment.targetHost = name;
                deployment.tags = lib.optional (lib.hasPrefix "client-" name) "nomad-client";
              }
            ]
            ++ imports;
        };
      };

      mkNodeN = nameFormat: wgIpFormat: imports: n: let
        n' = n + 1;
        fixed2 = lib.fixedWidthNumber 2 n';
        replace = lib.replaceStrings ["%02d" "%d"] [fixed2 (toString n')];
        name = replace nameFormat;
        wgIp = replace wgIpFormat;
      in
        mkNode name wgIp imports;

      mkNodes = count: nameFormat: wgIpFormat: imports:
        lib.foldl' lib.recursiveUpdate {} (
          lib.genList (mkNodeN nameFormat wgIpFormat imports) count
        );

      eu-central-1.aws.region = "eu-central-1";
      us-east-1.aws.region = "us-east-1";
      ap-southeast-2.aws.region = "ap-southeast-2";

      r5-xlarge.aws.instance.instance_type = "r5.xlarge";
      c5-4xlarge.aws.instance.instance_type = "c5.4xlarge";
      c5-2xlarge.aws.instance.instance_type = "c5.2xlarge";

      nixos-23-05.system.stateVersion = "23.05";

      volume = size: {aws.instance.root_block_device.volume_size = size;};

      inherit (nixosModules) common nomad-client nomad-server;
    in
      {
        meta.nixpkgs = import inputs.nixpkgs {system = "x86_64-linux";};
        defaults.imports = [common nixos-23-05];
      }
      // (mkNode "leader" "10.200.0.1" [eu-central-1 r5-xlarge nomad-server])
      // (mkNode "client-eu-18" "10.200.1.18" [eu-central-1 c5-4xlarge nomad-client])
      // (mkNodes 1 "client-eu-%02d" "10.200.1.%d" [eu-central-1 c5-2xlarge nomad-client])
      // (mkNodes 1 "client-ap-%02d" "10.200.2.%d" [ap-southeast-2 c5-2xlarge nomad-client])
      // (mkNodes 1 "client-us-%02d" "10.200.3.%d" [us-east-1 c5-2xlarge nomad-client]);
  };
}
