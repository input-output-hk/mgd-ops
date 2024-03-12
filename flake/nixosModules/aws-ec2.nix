{
  inputs,
  self,
  ...
}: {
  flake.nixosModules.aws-ec2 = {
    lib,
    name,
    ...
  }: {
    imports = [
      "${inputs.nixpkgs}/nixos/modules/virtualisation/amazon-image.nix"
    ];

    options = {
      aws = lib.mkOption {
        default = null;
        type = lib.types.nullOr (lib.types.submodule {
          options = {
            region = lib.mkOption {
              type = lib.types.str;
              default = self.cluster.infra.aws.region;
            };

            instance = lib.mkOption {
              type = lib.types.submodule {
                options = {
                  count = lib.mkOption {
                    type = lib.types.int;
                    default = 1;
                  };

                  instance_type = lib.mkOption {
                    type = lib.types.str;
                  };

                  root_block_device = lib.mkOption {
                    type = lib.types.attrs;
                  };

                  availability_zone = lib.mkOption {
                    type = lib.types.str;
                  };

                  tags = lib.mkOption {
                    type = lib.types.attrsOf lib.types.str;
                  };
                };
              };
            };

            route53 = lib.mkOption {
              default = null;
              type = lib.types.nullOr lib.types.anything;
            };
          };
        });
      };
    };

    config = {
      aws.instance.tags = {
        inherit (self.cluster.generic) organization tribe function repo;
        environment = name;
        group = name;
        Name = name;
      };
    };
  };
}
