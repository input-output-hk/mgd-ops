{
  imports = [
    ./zfs-kexec-image
    ./ssh-config
    ./pre-push
  ];

  perSystem = {
    inputs',
    pkgs,
    lib,
    ...
  }: {
    packages = {
      bootstrap = pkgs.callPackage ./bootstrap {};
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
