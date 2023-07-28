{...}: {
  AWSTemplateFormatVersion = "2010-09-09";
  Description = "Terraform state handling";

  Resources = {
    S3Bucket = {
      Type = "AWS::S3::Bucket";
      DeletionPolicy = "Retain";
      Properties = {
        BucketName = "cardano-perf-terraform";
        BucketEncryption.ServerSideEncryptionConfiguration = [
          {
            BucketKeyEnabled = false;
            ServerSideEncryptionByDefault.SSEAlgorithm = "AES256";
          }
        ];
        VersioningConfiguration.Status = "Enabled";
      };
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
