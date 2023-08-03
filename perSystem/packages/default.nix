{
  imports = [
    ./zfs-kexec-image
    ./pre-push
    ./go-discover
    ./nomad
  ];

  perSystem = {
    inputs',
    pkgs,
    ...
  }: {
    packages = {
      inherit (inputs'.nixpkgs-unstable.legacyPackages) rain;

      terraform = let
        inherit
          (inputs'.terraform-providers.legacyPackages.providers)
          hashicorp
          loafoe
          ;
      in
        pkgs.terraform.withPlugins (_: [
          hashicorp.aws
          hashicorp.external
          hashicorp.local
          hashicorp.null
          hashicorp.tls
          loafoe.ssh
        ]);
    };
  };
}
