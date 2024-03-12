{
  flake.nixosModules.nomad-ssd = {
    services.nomad.settings.client.host_volume = {
      "ssd1".path = "/ssd1";
      "ssd2".path = "/ssd2";
      "ssd3".path = "/ssd3";
      "ssd4".path = "/ssd4";
    };

    fileSystems = {
      "/ssd1" = {
        device = "/dev/nvme1n1";
        fsType = "ext2";
        autoFormat = true;
      };

      "/ssd2" = {
        device = "/dev/nvme2n1";
        fsType = "ext2";
        autoFormat = true;
      };

      "/ssd3" = {
        device = "/dev/nvme3n1";
        fsType = "ext2";
        autoFormat = true;
      };

      "/ssd4" = {
        device = "/dev/nvme4n1";
        fsType = "ext2";
        autoFormat = true;
      };
    };
  };
}
