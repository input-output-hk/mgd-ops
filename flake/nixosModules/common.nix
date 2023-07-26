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
      inputs.ragenix.nixosModules.age
      inputs.auth-keys-hub.nixosModules.auth-keys-hub
    ];

    age.secrets.github-token = {
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

    services.openssh = {
      enable = true;
      settings.PasswordAuthentication = false;
    };
  });
}
