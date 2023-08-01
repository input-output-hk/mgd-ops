{
  inputs,
  config,
  ...
}: let
  inherit (config.flake) nixosModules;
in {
  flake = {
    nixosConfigurations = (inputs.colmena.lib.makeHive config.flake.colmena).nodes;

    colmena = let
      eu-central-1.aws.region = "eu-central-1";
      us-east-1.aws.region = "us-east-1";

      r5-xlarge.aws.instance.instance_type = "r5.xlarge";
      c5-4xlarge.aws.instance.instance_type = "c5.4xlarge";

      nixos-23-05.system.stateVersion = "23.05";

      volume = size: {aws.instance.root_block_device.volume_size = size;};

      inherit (nixosModules) nomad-client nomad-master;

      mkNodes = count: region: type: 1;

      delete.aws.instance.count = 0;
    in {
      meta.nixpkgs = import inputs.nixpkgs {
        system = "x86_64-linux";
      };

      defaults.imports = [
        nixosModules.common
        nixosModules.aws-ec2
        nixos-23-05
      ];

      master = {imports = [eu-central-1 r5-xlarge (volume 100) nomad-master];};
      perf1 = {imports = [delete eu-central-1 c5-4xlarge (volume 60) nomad-client];};
      client-eu-01 = {imports = [eu-central-1 c5-4xlarge (volume 60) nomad-client];};
      client-us-01 = {imports = [us-east-1 r5-xlarge (volume 60) nomad-client];};
    };
  };
}
