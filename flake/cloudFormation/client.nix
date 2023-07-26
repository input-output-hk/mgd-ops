{
  inputs,
  name,
  amis,
  region,
  ...
}: {
  flake.cloudFormation.${name} = {
    Resources = {
      "${name}" = {
        Type = "AWS::EC2::Instance";
        Properties = {
          ImageId = amis."23.05".${region}.hvm-ebs;
          InstanceType = "t3a.medium";
          SecurityGroupIds = [{"Fn::GetAtt" = ["securityGroup" "GroupId"];}];
          KeyName.Ref = "key";

          BlockDeviceMappings = [
            {
              DeviceName = "/dev/xvda";
              Ebs = {
                DeleteOnTermination = true;
                Iops = 3000;
                VolumeSize = "100";
                VolumeType = "gp3";
              };
            }
          ];

          Tags = [
            {
              Key = "Name";
              Value = name;
            }
          ];
        };
      };

      securityGroup = {
        Type = "AWS::EC2::SecurityGroup";
        Properties = {
          GroupDescription = "clients";
          SecurityGroupIngress = [
            {
              Description = "allow SSH";
              IpProtocol = "tcp";
              CidrIp = "0.0.0.0/0";
              FromPort = 22;
              ToPort = 22;
            }
          ];
        };
      };

      key = {
        Type = "AWS::EC2::KeyPair";
        Properties.KeyName = "${name}-ssh-key";
      };

      eip = {
        Type = "AWS::EC2::EIP";
        Properties.InstanceId.Ref = name;
      };

      eipAssociation = {
        Type = "AWS::EC2::EIPAssociation";
        Properties = {
          EIP.Ref = "eip";
          InstanceId.Ref = name;
        };
      };
    };

    AWSTemplateFormatVersion = "2010-09-09";
    Description = "Stack for ${name}";

    Outputs = {
      AvailabilityZone.Value."Fn::GetAtt" = [name "AvailabilityZone"];
      PrivateDnsName.Value."Fn::GetAtt" = [name "PrivateDnsName"];
      PrivateIp.Value."Fn::GetAtt" = [name "PrivateIp"];
      PublicDnsName.Value."Fn::GetAtt" = [name "PublicDnsName"];
      PublicIp.Value."Fn::GetAtt" = [name "PublicIp"];
      InstanceId.Value.Ref = name;
      SecurityGroupGroupId.Value."Fn::GetAtt" = ["securityGroup" "GroupId"];
      SecurityGroupVpcId.Value."Fn::GetAtt" = ["securityGroup" "VpcId"];
      EipAllocationId.Value."Fn::GetAtt" = ["eip" "AllocationId"];
      EipPublicIp.Value."Fn::GetAtt" = ["eip" "PublicIp"];
      KeyName.Value.Ref = "key";
    };
  };
}
