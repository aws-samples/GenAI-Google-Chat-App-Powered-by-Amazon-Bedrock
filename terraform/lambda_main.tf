resource "aws_iam_role" "chat_app_main_role" {
  name = "chat-app-main-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "chat_app_main_basic_execution_attachment" {
  role       = aws_iam_role.chat_app_main_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_policy" "chat_app_main_policy" {
  name        = "chat-app-main-policy"
  description = "Policy for the main chat app Lambda function"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "bedrock:AssociateThirdPartyKnowledgeBase",
          "bedrock:CreateDataSource",
          "bedrock:CreateKnowledgeBase",
          "bedrock:CreateModelInvocationJob",
          "bedrock:DetectGeneratedContent",
          "bedrock:GetFoundationModel",
          "bedrock:GetFoundationModelAvailability",
          "bedrock:GetKnowledgeBase",
          "bedrock:GetModelInvocationLoggingConfiguration",
          "bedrock:InvokeModel",
          "bedrock:InvokeModelWithResponseStream",
          "bedrock:ListFoundationModels",
          "bedrock:ListKnowledgeBases",
          "bedrock:Retrieve",
          "bedrock:RetrieveAndGenerate",
          "bedrock:UpdateKnowledgeBase"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "dynamodb:BatchGetItem",
          "dynamodb:BatchWriteItem",
          "dynamodb:ConditionCheckItem",
          "dynamodb:DeleteItem",
          "dynamodb:DescribeTable",
          "dynamodb:GetItem",
          "dynamodb:GetRecords",
          "dynamodb:GetShardIterator",
          "dynamodb:PutItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:UpdateItem"
        ]
        Effect   = "Allow"
        Resource = aws_dynamodb_table.chat_history_table.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "chat_app_main_policy_attachment" {
  role       = aws_iam_role.chat_app_main_role.name
  policy_arn = aws_iam_policy.chat_app_main_policy.arn
}

resource "aws_lambda_function" "chat_app_main" {
  function_name = "chat-app-main"
  role          = aws_iam_role.chat_app_main_role.arn
  handler       = "lambda-chatapp-code.lambda_handler"
  runtime       = "python3.12"
  timeout       = 30
  
  # Read code from local lambda/lambda-chat-app directory
  source_code_hash = data.archive_file.lambda_chat_app_zip.output_base64sha256
  filename         = data.archive_file.lambda_chat_app_zip.output_path
  
  environment {
    variables = {
      dynamoDBTable = aws_dynamodb_table.chat_history_table.id
      kbId         = var.knowledge_base_id
      modelarn     = "arn:aws:bedrock:us-east-1::foundation-model/anthropic.claude-3-sonnet-20240229-v1:0"
      spaceId      = "spaceid"
    }
  }
  
  depends_on = [
    aws_iam_role.chat_app_main_role,
    aws_iam_role_policy_attachment.chat_app_main_policy_attachment,
    data.archive_file.lambda_chat_app_zip
  ]
}

# Create a zip file from the Lambda code directory
data "archive_file" "lambda_chat_app_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda/lambda-chat-app"
  output_path = "${path.module}/lambda_chatapp_code.zip"
}
