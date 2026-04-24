resource "aws_iam_role" "chat_app_authorizer_role" {
  name = "chat-app-authorizer-role"
  
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

resource "aws_iam_role_policy_attachment" "chat_app_authorizer_basic_execution_attachment" {
  role       = aws_iam_role.chat_app_authorizer_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "chat_app_authorizer" {
  function_name = "chat-app-authorizer"
  role          = aws_iam_role.chat_app_authorizer_role.arn
  handler       = "lambda-authorizer-code.lambda_handler"
  runtime       = "python3.12"
  timeout       = 30
  
  # Use the zip file with dependencies included
  source_code_hash = data.archive_file.lambda_auth_zip.output_base64sha256
  filename         = data.archive_file.lambda_auth_zip.output_path
  
  environment {
    variables = {
      CHAT_ISSUER = "chat@system.gserviceaccount.com"
      AUDIENCE    = aws_apigatewayv2_api.google_chat_app_http_api.api_endpoint
    }
  }
  
  depends_on = [
    aws_iam_role.chat_app_authorizer_role,
    data.archive_file.lambda_auth_zip,
    null_resource.install_lambda_auth_dependencies
  ]
}

# Install dependencies and create a zip file for the Lambda authorizer
resource "null_resource" "install_lambda_auth_dependencies" {
  triggers = {
    source_code_hash = sha1(join("", [for f in fileset("${path.module}/../lambda/lambda-auth", "*"): filesha1("${path.module}/../lambda/lambda-auth/${f}")]))
  }

  provisioner "local-exec" {
    command = <<EOT
      mkdir -p ${path.module}/lambda_auth_package
      cp -r ${path.module}/../lambda/lambda-auth/* ${path.module}/lambda_auth_package/
      pip3 install -r ${path.module}/../lambda/lambda-auth/requirements.txt -t ${path.module}/lambda_auth_package/
    EOT
  }
}

data "archive_file" "lambda_auth_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda_auth_package"
  output_path = "${path.module}/lambda_authorizer_code.zip"
  depends_on  = [null_resource.install_lambda_auth_dependencies]
}
