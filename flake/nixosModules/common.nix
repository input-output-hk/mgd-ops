parts @ {
  self,
  inputs,
  moduleWithSystem,
  ...
}: {
  flake.nixosModules.common = moduleWithSystem ({inputs'}: {
    name,
    options,
    config,
    pkgs,
    lib,
    nodes,
    ...
  }: {
    imports = [
      parts.config.flake.nixosModules.wireguard
      inputs.sops-nix.nixosModules.default
      inputs.auth-keys-hub.nixosModules.auth-keys-hub
    ];

    sops.secrets.github-token = {
      file = "${self}/secrets/github-token.age";
      owner = config.programs.auth-keys-hub.user;
      inherit (config.programs.auth-keys-hub) group;
    };

    programs.auth-keys-hub = {
      enable = true;
      package = inputs'.auth-keys-hub.packages.auth-keys-hub;
      github = {
        teams = [
          "input-output-hk/performance-tracing"
          "input-output-hk/node-sre"
        ];
        tokenFile = config.age.secrets.github-token.path;
      };
    };

    services = {
      chrony.enable = true;
      openssh = {
        enable = true;
        settings.PasswordAuthentication = false;
      };
    };
  });
}
