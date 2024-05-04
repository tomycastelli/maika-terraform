resource "aws_api_gateway_rest_api" "lambda_api" {
  name        = "pdfGenerator"
  description = "API Gateway for the pdfGenerator lambda function"
}

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  parent_id   = aws_api_gateway_rest_api.lambda_api.root_resource_id
  path_part   = "pdf"
}

resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = aws_api_gateway_rest_api.lambda_api.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "ANY"
  authorization = "NONE"
  api_key_required = true
}

resource "aws_api_gateway_integration" "lambda" {
  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  resource_id = aws_api_gateway_method.proxy.resource_id
  http_method = aws_api_gateway_method.proxy.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.pdfGenerator.invoke_arn
}

resource "aws_api_gateway_deployment" "gateway" {
  depends_on = [
    aws_api_gateway_integration.lambda,
  ]

  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  stage_name  = "dev"
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.pdfGenerator.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.lambda_api.execution_arn}/*/*/pdf"
}

resource "aws_api_gateway_api_key" "sistema-maika" {
  name = "sistema-maika"
}

resource "aws_api_gateway_usage_plan" "lambda-functions" {
  name = "Lambda Functions"

  api_stages {
    api_id = aws_api_gateway_rest_api.lambda_api.id
    stage  = "dev"
  }

  throttle_settings {
    burst_limit = 10
    rate_limit  = 10
  }
}

resource "aws_api_gateway_usage_plan_key" "main" {
  key_id        = aws_api_gateway_api_key.sistema-maika.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.lambda-functions.id
}