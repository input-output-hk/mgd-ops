{
  imports = [
    ./aws-ec2.nix
    ./common.nix
    ./nomad-master.nix
    ./nomad-client.nix
    ./wireguard.nix
  ];
}
