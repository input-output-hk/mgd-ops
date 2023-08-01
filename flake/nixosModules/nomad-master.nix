{
  flake.nixosModules.nomad-master = {
    deployment.tags = ["nomad-master"];
    services.nomad = {
      enable = true;
      settings = {
        server = {
          enabled = true;
          bootstrap_expect = 1;
        };
      };
    };
  };
}
