provider "aws" {
  region = var.region
}

# Output the API Gateway endpoint URL
output "api_endpoint" {
  value = aws_apigatewayv2_api.google_chat_app_http_api.api_endpoint
}
