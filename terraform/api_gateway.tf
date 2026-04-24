resource "aws_apigatewayv2_api" "google_chat_app_http_api" {
  name          = "Google_Chat_App_HTTP_Api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.google_chat_app_http_api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_apigatewayv2_authorizer" "lambda_chat_app_authorizer" {
  api_id           = aws_apigatewayv2_api.google_chat_app_http_api.id
  authorizer_type  = "REQUEST"
  identity_sources = ["$request.header.Authorization"]
  name             = "lambda-chat-app-Authorizer"
  
  authorizer_uri                      = aws_lambda_function.chat_app_authorizer.invoke_arn
  authorizer_payload_format_version   = "2.0"
  authorizer_result_ttl_in_seconds    = 300
  enable_simple_responses             = true
}

resource "aws_apigatewayv2_integration" "chat_app_integration" {
  api_id                 = aws_apigatewayv2_api.google_chat_app_http_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.chat_app_main.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "chat_app_route" {
  api_id         = aws_apigatewayv2_api.google_chat_app_http_api.id
  route_key      = "POST /"
  target         = "integrations/${aws_apigatewayv2_integration.chat_app_integration.id}"
  
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.lambda_chat_app_authorizer.id
}

resource "aws_lambda_permission" "api_gateway_chat_app_main" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.chat_app_main.function_name
  principal     = "apigateway.amazonaws.com"
  
  source_arn = "${aws_apigatewayv2_api.google_chat_app_http_api.execution_arn}/*/*/"
}

resource "aws_lambda_permission" "api_gateway_chat_app_authorizer" {
  statement_id  = "AllowExecutionFromAPIGatewayAuthorizer"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.chat_app_authorizer.function_name
  principal     = "apigateway.amazonaws.com"
  
  source_arn = "${aws_apigatewayv2_api.google_chat_app_http_api.execution_arn}/authorizers/${aws_apigatewayv2_authorizer.lambda_chat_app_authorizer.id}"
}
