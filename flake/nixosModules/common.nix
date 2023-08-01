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

    networking.hostName = name;
    deployment.targetHost = name;

    sops.secrets.github-token = {
      sopsFile = "${self}/secrets/github-token";
      format = "binary";
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
        tokenFile = config.sops.secrets.github-token.path;
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
