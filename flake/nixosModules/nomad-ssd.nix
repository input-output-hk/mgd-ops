{
  flake.nixosModules.nomad-ssd = {
    nix.settings.system-features = ["benchmark"];

    services.nomad.settings.client.host_volume = {
      "ssd1".path = "/ssd1";
      "ssd2".path = "/ssd2";
    };

    fileSystems = {
      "/ssd1" = {
        device = "/dev/nvme1n1";
        fsType = "ext2";
        autoFormat = true;
        options = ["noatime" "nodiratime" "noacl"];
      };

      "/ssd2" = {
        device = "/dev/nvme2n1";
        fsType = "ext2";
        autoFormat = true;
        options = ["noatime" "nodiratime" "noacl"];
      };
    };
  };
}
