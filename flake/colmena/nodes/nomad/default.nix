{
  system.stateVersion = "23.05";
  deployment.tags = ["nomad"];
  aws.region = "eu-central-1";
  aws.instance.instance_type = "r5.xlarge";
  aws.instance.root_block_device.volume_size = 100;
}
