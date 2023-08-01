let
  name = "perf2";
in {
  networking.hostName = name;
  system.stateVersion = "23.05";

  deployment = {
    targetHost = name;
    tags = ["master"];
  };

  aws.region = "us-east-2";

  aws_instance = {
    instance_type = "c5.2xlarge";
    tags.Name = name;
  };
}
