{inputs, ...}: {
  flake.nixosModules.aws-t3a-medium = {...}: {
    imports = [
      "${inputs.nixpkgs}/nixos/modules/virtualisation/amazon-image.nix"
    ];
  };
}
