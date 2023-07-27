{...}: {
  AWSTemplateFormatVersion = "2010-09-09";
  Description = "Terraform state handling";

  Resources = {
    S3Bucket = {
      Type = "AWS::S3::Bucket";
      Properties = {
        BucketName = "cardano-perf-terraform";
        BucketEncryption.ServerSideEncryptionConfiguration = [{BucketKeyEnabled = true;}];
        VersioningConfiguration.Status = "Enabled";
      };
    };

    # Terraform has no way to avoid leaking the private key in the state file,
    # so we put that here instead.
    # We can retrieve the private key later via `aws ssm get-parameter`.
    SSHKey = {
      Type = "AWS::EC2::KeyPair";
      Properties.KeyName = "ssh_key";
    };

    DynamoDB = {
      Type = "AWS::DynamoDB::Table";
      Properties = {
        TableName = "terraform";

        KeySchema = [
          {
            AttributeName = "LockID";
            KeyType = "HASH";
          }
        ];

        AttributeDefinitions = [
          {
            AttributeName = "LockID";
            AttributeType = "S";
          }
        ];

        ProvisionedThroughput = {
          ReadCapacityUnits = 1;
          WriteCapacityUnits = 1;
        };
      };
    };
  };
}
