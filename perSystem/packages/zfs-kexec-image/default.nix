{inputs, ...}: {
  perSystem = {
    inputs',
    pkgs,
    lib,
    ...
  }: {
    packages = lib.optionalAttrs pkgs.stdenv.isLinux {
      zfs-kexec-image =
        (inputs'.nixpkgs.legacyPackages.nixos [
          inputs.nixos-images.nixosModules.kexec-installer
          inputs.nixos-images.nixosModules.noninteractive
          {
            boot.supportedFilesystems = ["zfs"];
            networking.hostId = "deadbeef";
          }
        ])
        .config
        .system
        .build
        .kexecTarball;
    };
  };
}
