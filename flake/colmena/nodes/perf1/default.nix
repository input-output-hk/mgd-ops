{
  networking.hostName = "perf1";
  system.stateVersion = "23.05";

  deployment = {
    targetHost = "perf1";
    tags = ["master"];
  };
}
