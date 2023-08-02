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
      eu-central-1.aws.region = "eu-central-1";
      us-east-1.aws.region = "us-east-1";
      ap-southeast-2.aws.region = "ap-southeast-2";

      r5-xlarge.aws.instance.instance_type = "r5.xlarge";
      c5-4xlarge.aws.instance.instance_type = "c5.4xlarge";
      c5-2xlarge.aws.instance.instance_type = "c5.2xlarge";

      nixos-23-05.system.stateVersion = "23.05";

      volume = size: {aws.instance.root_block_device.volume_size = size;};

      inherit (nixosModules) nomad-client nomad-master;

      wireguardIps = {
        eu-central-1 = "10.200.0";
        us-east-1 = "10.200.1";
        ap-southeast-2 = "10.200.2";
      };

      wireguard = region: suffix: {
        networking.wireguard.interfaces.wg0.ips = ["${wireguardIps.${region}}.${toString suffix}/32"];
      };

      mkNode = num: region: imports: let
        shortRegion = lib.substring 0 2 region.aws.region;
        suffix = lib.fixedWidthNumber 2 num;
        wg = wireguard region.aws.region (num + 1);
      in {
        "client-${shortRegion}-${suffix}" = {imports = [region (volume 60) wg] ++ imports;};
      };

      mkNodes = count: region: imports:
        lib.foldl' lib.recursiveUpdate {} (
          lib.genList (num: mkNode (num + 1) region imports) count
        );

      delete.aws.instance.count = 0;
    in (
      {
        meta.nixpkgs = import inputs.nixpkgs {
          system = "x86_64-linux";
        };

        defaults.imports = [
          nixosModules.common
          nixosModules.aws-ec2
          nixos-23-05
        ];

        master = {imports = [eu-central-1 r5-xlarge (volume 100) nomad-master (wireguard "eu-central-1" 1)];};
      }
      // (mkNodes 1 ap-southeast-2 [c5-2xlarge nomad-client])
      // (mkNodes 1 us-east-1 [c5-2xlarge nomad-client])
      // (mkNodes 1 eu-central-1 [c5-2xlarge nomad-client])
      // (mkNode 18 eu-central-1 [c5-4xlarge nomad-client])
    );
  };
}
