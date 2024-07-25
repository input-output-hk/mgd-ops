{
  inputs,
  self,
  lib,
  config,
  ...
}: let
  inherit (config.flake) cluster;
  amis = import "${inputs.nixpkgs}/nixos/modules/virtualisation/ec2-amis.nix";

  underscore = lib.replaceStrings ["-"] ["_"];
  awsProviderFor = region: "aws.${underscore region}";

  nixosConfigurations = lib.mapAttrs (_: node: node.config) config.flake.nixosConfigurations;
  nodes = lib.filterAttrs (_: node: node.aws != null) nixosConfigurations;
  mapNodes = f: lib.mapAttrs f nodes;

  regions =
    lib.mapAttrsToList (region: enabled: {
      region = underscore region;
      count =
        if enabled
        then 1
        else 0;
    })
    cluster.regions;

  mapRegions = f: lib.foldl' lib.recursiveUpdate {} (lib.forEach regions f);
in {
  flake.terraform.cluster = inputs.terranix.lib.terranixConfiguration {
    system = "x86_64-linux";
    modules = [
      {
        terraform = {
          required_providers = {
            aws.source = "opentofu/aws";
            local.source = "opentofu/local";
            tls.source = "opentofu/tls";
          };

          backend = {
            s3 = {
              bucket = cluster.bucketName;
              key = "terraform";
              inherit (cluster) region;
              dynamodb_table = "terraform";
            };
          };
        };

        provider.aws = lib.forEach (builtins.attrNames cluster.regions) (region: {
          inherit region;
          alias = underscore region;
          default_tags.tags = self.cluster.generic;
        });

        # Common parameters:
        #   data.aws_caller_identity.current.account_id
        #   data.aws_region.current.name
        data = {
          aws_caller_identity.current = {};
          aws_region.current = {};
          aws_route53_zone.selected.name = "${cluster.domain}.";
        };

        resource = {
          aws_instance = mapNodes (
            _: node:
              {
                inherit (node.aws.instance) count instance_type tags;
                provider = awsProviderFor node.aws.region;
                ami = amis.${node.system.stateVersion}.${node.aws.region}.hvm-ebs;
                iam_instance_profile = "\${aws_iam_instance_profile.ec2_profile.name}";
                monitoring = true;
                key_name = "\${aws_key_pair.bootstrap_${underscore node.aws.region}[0].key_name}";
                vpc_security_group_ids = [
                  "\${aws_security_group.common_${underscore node.aws.region}[0].id}"
                ];

                root_block_device = {
                  volume_type = "gp3";
                  inherit (node.aws.instance.root_block_device) volume_size;
                  iops = 3000;
                  delete_on_termination = true;
                };

                metadata_options = {
                  http_endpoint = "enabled";
                  http_put_response_hop_limit = 2;
                  http_tokens = "optional";
                };

                lifecycle = [{ignore_changes = ["ami" "user_data"];}];
              }
              // lib.optionalAttrs (node.aws.instance ? availability_zone) {
                inherit (node.aws.instance) availability_zone;
              }
          );

          aws_iam_instance_profile.ec2_profile = {
            name = "ec2Profile";
            role = "\${aws_iam_role.ec2_role.name}";
          };

          aws_iam_role.ec2_role = {
            name = "ec2Role";
            assume_role_policy = builtins.toJSON {
              Version = "2012-10-17";
              Statement = [
                {
                  Action = "sts:AssumeRole";
                  Effect = "Allow";
                  Principal.Service = "ec2.amazonaws.com";
                }
              ];
            };
          };

          aws_iam_role_policy_attachment = let
            mkRoleAttachments = roleResourceName: policyList:
              lib.listToAttrs (map (policy: {
                  name = "${roleResourceName}_policy_attachment_${policy}";
                  value = {
                    role = "\${aws_iam_role.${roleResourceName}.name}";
                    policy_arn = "\${aws_iam_policy.${policy}.arn}";
                  };
                })
                policyList);
          in
            lib.foldl' lib.recursiveUpdate {} [
              (mkRoleAttachments "ec2_role" ["kms_user" "ec2_discover"])
            ];

          aws_iam_policy.kms_user = {
            name = "kmsUser";
            policy = builtins.toJSON {
              Version = "2012-10-17";
              Statement = [
                {
                  Effect = "Allow";
                  Action = ["kms:Decrypt" "kms:DescribeKey"];

                  # KMS `kmsKey` is bootstrapped by cloudFormation rain.
                  # Scope this policy to a specific resource to allow for multiple keys and key policies.
                  # Resource = "arn:aws:kms:\${data.aws_region.current.name}:\${data.aws_caller_identity.current.account_id}:alias/kmsKey";
                  Resource = "arn:aws:kms:*:\${data.aws_caller_identity.current.account_id}:key/*";
                  Condition."ForAnyValue:StringLike"."kms:ResourceAliases" = "alias/kmsKey";
                }
              ];
            };
          };

          aws_iam_policy.ec2_discover = {
            name = "ec2_discover";
            policy = builtins.toJSON {
              Version = "2012-10-17";
              Statement = [
                {
                  Effect = "Allow";
                  Action = ["ec2:DescribeInstances"];
                  Resource = "*";
                }
              ];
            };
          };

          tls_private_key.bootstrap.algorithm = "ED25519";

          aws_key_pair = mapRegions ({
            count,
            region,
          }: {
            "bootstrap_${region}" = {
              inherit count;
              provider = awsProviderFor region;
              key_name = "bootstrap";
              public_key = "\${tls_private_key.bootstrap.public_key_openssh}";
            };
          });

          aws_eip = mapNodes (name: node: {
            inherit (node.aws.instance) count tags;
            provider = awsProviderFor node.aws.region;
            instance = "\${aws_instance.${name}[0].id}";
          });

          aws_eip_association = mapNodes (name: node: {
            inherit (node.aws.instance) count;
            provider = awsProviderFor node.aws.region;
            instance_id = "\${aws_instance.${name}[0].id}";
            allocation_id = "\${aws_eip.${name}[0].id}";
          });

          aws_ebs_volume.deployer_volume = {
            availability_zone = "\${aws_instance.deployer[0].availability_zone}";
            type = "gp3";
            iops = 3000;
            throughput = 125; # MB/s
            size = 12000;
          };

          aws_volume_attachment.deployer_volume = {
            device_name = "/dev/sdh";
            volume_id = "\${ aws_ebs_volume.deployer_volume.id }";
            instance_id = "\${aws_instance.deployer[0].id}";
          };

          # To remove or rename a security group, keep it here while removing
          # the reference from the instance. Then apply, and if that succeeds,
          # remove the group here and apply again.
          aws_security_group = let
            mkRule = lib.recursiveUpdate {
              protocol = "tcp";
              cidr_blocks = ["0.0.0.0/0"];
              ipv6_cidr_blocks = ["::/0"];
              prefix_list_ids = [];
              security_groups = [];
              self = true;
            };
          in
            mapRegions ({
              region,
              count,
            }: {
              "common_${region}" = {
                inherit count;
                provider = awsProviderFor region;
                name = "common";
                description = "Allow common ports";
                lifecycle = [{create_before_destroy = true;}];

                ingress = [
                  (mkRule {
                    description = "Allow SSH";
                    from_port = 22;
                    to_port = 22;
                  })
                  (mkRule {
                    description = "Allow HTTP";
                    from_port = 80;
                    to_port = 80;
                  })
                  (mkRule {
                    description = "Allow HTTPS";
                    from_port = 443;
                    to_port = 443;
                  })
                  (mkRule {
                    description = "Allow Rsync";
                    from_port = 32000;
                    to_port = 32000;
                  })
                  (mkRule {
                    description = "Allow Cardano";
                    from_port = 30000;
                    to_port = 30052;
                  })
                  (mkRule {
                    description = "Indexer";
                    from_port = 3000;
                    to_port = 3000;
                  })
                  (mkRule {
                    description = "TBD";
                    from_port = 3080;
                    to_port = 3080;
                  })
                  (mkRule {
                    description = "Proofd";
                    from_port = 33380;
                    to_port = 33380;
                  })
                  (mkRule {
                    description = "Allow Wireguard";
                    from_port = 51820;
                    to_port = 51820;
                    protocol = "udp";
                  })
                  (mkRule {
                    description = "Allow ICMP";
                    from_port = 8;
                    to_port = 0;
                    protocol = "icmp";
                  })
                ];

                egress = [
                  (mkRule {
                    description = "Allow outbound traffic";
                    from_port = 0;
                    to_port = 0;
                    protocol = "-1";
                  })
                ];
              };
            });

          # mapNodes = f: lib.mapAttrs f nodes;
          aws_route53_record =
            # lib.mapAttrs' (
            #   _: nodeConf:
            #     map (record: {
            #       name = builtins.hashString "md5" record.name;
            #       value = record;
            #     })
            #     nodeConf.aws.aws_route53_record
            # )
            # nodes;
            builtins.listToAttrs (lib.flatten (builtins.attrValues (lib.mapAttrs (nodeName: node:
              map (record: {
                name = "${nodeName}-${record.type}-${builtins.hashString "md5" record.name}";
                value = record;
              })
              node.aws.aws_route53_record)
            nodes)));

          local_file.ssh_config = {
            filename = "\${path.module}/.ssh_config";
            file_permission = "0600";
            content = ''
              Host *
                User root
                UserKnownHostsFile /dev/null
                StrictHostKeyChecking no
                IdentityFile .ssh_key
                ServerAliveCountMax 2
                ServerAliveInterval 60

              ${
                builtins.concatStringsSep "\n" (map (name: ''
                    Host ${name}
                      HostName ''${aws_eip.${name}[0].public_ip}
                  '')
                  (builtins.attrNames (lib.filterAttrs (_: node: node.aws.instance.count > 0) nodes)))
              }
            '';
          };
        };
      }
    ];
  };
}
