# Google Chat Bot Terraform Configuration

This Terraform configuration deploys a Google Chat App powered by Amazon Bedrock. It creates the necessary AWS resources including Lambda functions, API Gateway, DynamoDB table, and IAM roles/policies.

## Prerequisites

- Terraform installed
- AWS CLI configured with appropriate credentials
- Amazon Bedrock Knowledge base created
- Amazon Bedrock models enabled in your AWS account

## Structure

The Terraform configuration is organized into the following files:

- `main.tf` - Main configuration file with provider settings
- `variables.tf` - Input variables definition
- `dynamodb.tf` - DynamoDB table configuration
- `lambda_authorizer.tf` - Lambda authorizer function and related resources
- `lambda_main.tf` - Main Lambda function and related resources
- `api_gateway.tf` - API Gateway configuration

## Required Variables

- `knowledge_base_id` - The ID for the knowledge bases for Amazon Bedrock
- `llm_model` - The LLM model to be used for text generation on Amazon Bedrock (default: "Anthropic-Claude-Sonnet-3")
- `region` - AWS region to deploy resources

## Lambda Function Code

**Note:** This Terraform configuration references Lambda function code that needs to be provided separately:

1. `lambda_authorizer_code.zip` - Contains the code for the authorizer Lambda function
2. `lambda_chatapp_code.zip` - Contains the code for the main chat application Lambda function

You need to create these ZIP files with the appropriate code before applying this Terraform configuration.

## Usage

1. Initialize Terraform:
   ```
   terraform init
   ```

2. Review the execution plan:
   ```
   terraform plan -var="knowledge_base_id=YOUR_KB_ID" -var="region=us-east-1"
   ```

3. Apply the configuration:
   ```
   terraform apply -var="knowledge_base_id=YOUR_KB_ID" -var="region=us-east-1"
   ```

4. After successful deployment, the API Gateway endpoint URL will be displayed in the outputs.

## Integration with Google Chat

After deploying this infrastructure, you'll need to register a new app in the Google Cloud portal and configure it to use the API Gateway endpoint URL. Refer to the Google developer's guide for detailed instructions on how to publish your app to Google Chat.
