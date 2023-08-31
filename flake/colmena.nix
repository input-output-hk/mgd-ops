{
  inputs,
  config,
  lib,
  ...
}: let
  inherit (config.flake) nixosModules;
in {
  flake.colmena = let
    mkNode = name: wgIp: imports: {
      "${name}" = {
        imports =
          [
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

    eu-central-1b.aws = {
      region = "eu-central-1";
      instance.availability_zone = "eu-central-1b";
    };

    eu-central-1c = {
      aws.region = "eu-central-1";
      aws.instance.availability_zone = "eu-central-1c";
    };

    us-east-1.aws.region = "us-east-1";
    ap-southeast-2.aws.region = "ap-southeast-2";

    r5-xlarge.aws.instance.instance_type = "r5.xlarge";
    m5-4xlarge.aws.instance.instance_type = "m5.4xlarge";
    c5-2xlarge.aws.instance.instance_type = "c5.2xlarge";
    c5-9xlarge.aws.instance.instance_type = "c5.9xlarge";

    nixos-23-05.system.stateVersion = "23.05";

    ebs = size: {aws.instance.root_block_device.volume_size = lib.mkDefault size;};

    inherit (nixosModules) common nomad-client nomad-server deployer;
  in
    {
      meta.nixpkgs = import inputs.nixpkgs {system = "x86_64-linux";};
      defaults.imports = [common nixos-23-05];
    }
    // (mkNode "leader" "10.200.0.1" [eu-central-1c r5-xlarge nomad-server (ebs 40)])
    // (mkNode "deployer" "10.200.0.2" [eu-central-1b c5-9xlarge deployer (ebs 2000)])
    // (mkNode "explorer" "10.200.1.19" [eu-central-1b m5-4xlarge nomad-client (ebs 40)])
    // (mkNodes 18 "client-eu-%02d" "10.200.1.%d" [eu-central-1b c5-2xlarge nomad-client (ebs 40)])
    // (mkNodes 17 "client-ap-%02d" "10.200.2.%d" [ap-southeast-2 c5-2xlarge nomad-client (ebs 40)])
    // (mkNodes 17 "client-us-%02d" "10.200.3.%d" [us-east-1 c5-2xlarge nomad-client (ebs 40)]);
}
