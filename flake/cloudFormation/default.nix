{inputs, ...}: let
  amis = import "${inputs.nixpkgs}/nixos/modules/virtualisation/ec2-amis.nix";
in {
  flake.cloudFormation = {
    # eu-central-1 c5.2xlarge * 18
    # eu-central-1 c5.4xlarge * 1
    # us-east-1 c5.2xlarge * 17
    # ap-southeast-2 c5.2xlarge * 17
    eu-central-1-1 = import ./client.nix {
      name = "eu-central-1-1";
      region = "eu-central-1";
      type = "c5.2xlarge";
      inherit inputs amis;
    };

    eu-central-1-2 = import ./client.nix {
      name = "eu-central-1-2";
      region = "eu-central-1";
      inherit inputs amis;
    };

    eu-central-1-3 = import ./client.nix {
      name = "eu-central-1-3";
      region = "eu-central-1";
      inherit inputs amis;
    };
  };
}
