{
  inputs,
  self,
  ...
}: let
  amis = import "${inputs.nixpkgs}/nixos/modules/virtualisation/ec2-amis.nix";
  inherit (self) nixosConfigurations;
in {
  flake.terraform.test = inputs.terranix.lib.terranixConfiguration {
    system = "x86_64-linux";
    modules = [
      {
        terraform = {
          required_providers = {
            aws.source = "hashicorp/aws";
            null.source = "hashicorp/null";
            local.source = "hashicorp/local";
          };

          backend = {
            s3 = {
              bucket = "cardano-perf-terraform";
              key = "terraform";
              region = "eu-central-1";
              dynamodb_table = "terraform";
            };
          };
        };

        resource = {
          aws_instance.perf1 = {
            instance_type = "c5.2xlarge";
            ami = amis."23.05".eu-central-1.hvm-ebs;
            monitoring = true;
            key_name = "ssh_key";
            security_groups = ["allow_ssh"];
            tags.Name = "perf1";

            root_block_device = {
              volume_type = "gp3";
              volume_size = 40;
              iops = 3000;
              delete_on_termination = true;
            };

            lifecycle = [{ignore_changes = ["ami" "user_data"];}];
          };

          aws_eip.perf1.instance = "\${aws_instance.perf1.id}";

          aws_eip_association.perf1 = {
            instance_id = "\${aws_instance.perf1.id}";
            allocation_id = "\${aws_eip.perf1.id}";
          };

          aws_security_group.allow_ssh = {
            name = "allow_ssh";
            description = "Allow SSH";

            ingress = [
              {
                description = "Allow SSH";
                from_port = 22;
                to_port = 22;
                protocol = "tcp";
                cidr_blocks = ["0.0.0.0/0"];
                ipv6_cidr_blocks = ["::/0"];
                prefix_list_ids = [];
                security_groups = [];
                self = true;
              }
            ];

            egress = [
              {
                description = "Allow outbound traffic";
                from_port = 0;
                to_port = 0;
                protocol = "-1";
                cidr_blocks = ["0.0.0.0/0"];
                ipv6_cidr_blocks = ["::/0"];
                prefix_list_ids = [];
                security_groups = [];
                self = true;
              }
            ];
          };

          local_file.ssh_config = {
            filename = "\${path.module}/.ssh_config";
            content = builtins.concatStringsSep "\n" (map (name: ''
                Host ${name}
                  HostName ''${aws_eip.${name}.public_ip}
                  User root
                  UserKnownHostsFile /dev/null
                  StrictHostKeyChecking no
              '')
              (builtins.attrNames nixosConfigurations));
          };
        };
      }
    ];
  };
}
