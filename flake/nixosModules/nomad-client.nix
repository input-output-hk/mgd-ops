{
  flake.nixosModules.nomad-client = {
    deployment.tags = ["nomad-client"];

    services.nomad = {
      enable = true;
      settings = {
        client = {
          enabled = true;
        };
      };
    };
  };
}
