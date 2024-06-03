# S3-SNS-SQS-Lambda

## Description

- This sample deploys a Terraform configuration
- Copies a log file into an S3 bucket
- Sends a notification to an SNS
- Broadcast to SQS queue(s)
- Lambda retrieves a message from an SQS queue

## Prerequisites

- Terraform
- LocalStack
- AWS CLI
- jq

## Deployment

1. Clone the repository and navigate to the sample directory.

- Run the `./deploy.sh` script to deploy the full sample.

## Files

- `./deploy.sh`:  Deployment script
- `main.tf`: Terraform configuration file
- `provider.tf`: Terraform provider configuration file
- `lambda/index.py`: Lambda codes
- `/test/some-log-file.log`: Sample log file



## Ref
- https://spacelift.io/blog/terraform-aws-lambda
- https://www.youtube.com/watch?v=O2j8k7j9mLM&ab_channel=ListenToLearn
- https://github.com/jupitercl/aws-localstack-terraform-sns-sqs-lambda
- https://hashnode.localstack.cloud/testing-s3-notifications-locally-with-localstack-terraform