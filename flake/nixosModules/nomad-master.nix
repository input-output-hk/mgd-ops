{
  flake.nixosModules.nomad-master = {
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
