{self, ...}: {
  flake.nixosModules.nix-private = {config, ...}: {
    sops.secrets.nix-access-tokens.sopsFile = "${self}/secrets/nix-access-tokens.enc";

    nix.extraOptions = ''
      !include ${config.sops.secrets.nix-access-tokens.path}
    '';
  };
}
