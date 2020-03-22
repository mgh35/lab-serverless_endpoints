provider "aws" {
  profile    = "postboard"
  region     = "us-east-1"
}

variable "file" {
  default = "../.pkg/v0.0.1.zip"
}

resource "aws_iam_role" "cloudwatch" {
  name = "cloudwatch"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "cloudwatch" {
  name = "cloudwatch"
  role = aws_iam_role.cloudwatch.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:DescribeLogGroups",
                "logs:DescribeLogStreams",
                "logs:PutLogEvents",
                "logs:GetLogEvents",
                "logs:FilterLogEvents"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_role" "lambda" {
  name = "lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "lambda" {
  name        = "lambda"
  role        = aws_iam_role.lambda.id

  # 1) Allow calling other lambdas
  # 2) Turn on logging
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
       {
          "Effect": "Allow",
          "Action": [
              "lambda:InvokeFunction"
          ],
          "Resource": "*"
      },
      {
        "Action": [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource": "arn:aws:logs:*:*:*",
        "Effect": "Allow"
      }
    ]
}
EOF
}

resource "aws_iam_role" "apigw_auth_invocation" {
  name = "apigw_auth_invocation"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "apigw_auth_invocation_policy" {
  name = "apigw_auth_invocation_policy"
  role = aws_iam_role.apigw_auth_invocation.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "lambda:InvokeFunction",
      "Effect": "Allow",
      "Resource": "${aws_lambda_function.authorizer.arn}"
    }
  ]
}
EOF
}

resource "aws_lambda_function" "authorizer" {
  role             = aws_iam_role.lambda.arn
  handler          = "auth.authorizer"
  runtime          = "python3.6"
  filename         = var.file
  function_name    = "authorizer"
  source_code_hash = filebase64sha256(var.file)
}

resource "aws_lambda_function" "random_word" {
  role             = aws_iam_role.lambda.arn
  handler          = "handlers.random_word"
  runtime          = "python3.6"
  filename         = var.file
  function_name    = "random_word"
  source_code_hash = filebase64sha256(var.file)
}

resource "aws_lambda_function" "call_random_word" {
  role             = aws_iam_role.lambda.arn
  handler          = "handlers.call_random_word"
  runtime          = "python3.6"
  filename         = var.file
  function_name    = "call_random_word"
  source_code_hash = filebase64sha256(var.file)
}

resource "aws_api_gateway_account" "postboard" {
  cloudwatch_role_arn = aws_iam_role.cloudwatch.arn
}

resource "aws_api_gateway_rest_api" "postboard" {
  name        = "Postboard"
  description = "Postboard App"
}

resource "aws_api_gateway_authorizer" "token" {
  name                   = "token"
  rest_api_id            = aws_api_gateway_rest_api.postboard.id
  authorizer_uri         = aws_lambda_function.authorizer.invoke_arn
  authorizer_credentials = aws_iam_role.apigw_auth_invocation.arn
}

resource "aws_api_gateway_deployment" "test" {
  depends_on = [
   aws_api_gateway_integration.random_word
  ]

  rest_api_id = aws_api_gateway_rest_api.postboard.id
  stage_name = "test"
}

resource "aws_api_gateway_method_settings" "all" {
  rest_api_id = aws_api_gateway_rest_api.postboard.id
  stage_name  = aws_api_gateway_deployment.test.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled = true
    logging_level   = "INFO"
  }
}

resource "aws_api_gateway_resource" "api" {
  rest_api_id = aws_api_gateway_rest_api.postboard.id
  parent_id   = aws_api_gateway_rest_api.postboard.root_resource_id
  path_part   = "api"
}

resource "aws_api_gateway_resource" "api_random_word" {
  rest_api_id = aws_api_gateway_rest_api.postboard.id
  parent_id   = aws_api_gateway_resource.api.id
  path_part   = "random_word"
}

resource "aws_api_gateway_method" "GET__random_word" {
  rest_api_id   = aws_api_gateway_rest_api.postboard.id
  resource_id   = aws_api_gateway_resource.api_random_word.id
  http_method   = "GET"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.token.id
}

resource "aws_api_gateway_integration" "random_word" {
  rest_api_id = aws_api_gateway_rest_api.postboard.id
  resource_id = aws_api_gateway_method.GET__random_word.resource_id
  http_method = aws_api_gateway_method.GET__random_word.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.random_word.invoke_arn
}

resource "aws_api_gateway_resource" "api_call_random_word" {
  rest_api_id = aws_api_gateway_rest_api.postboard.id
  parent_id   = aws_api_gateway_resource.api.id
  path_part   = "call_random_word"
}

resource "aws_api_gateway_method" "GET__call_random_word" {
  rest_api_id   = aws_api_gateway_rest_api.postboard.id
  resource_id   = aws_api_gateway_resource.api_call_random_word.id
  http_method   = "GET"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.token.id
}

resource "aws_api_gateway_integration" "call_random_word" {
  rest_api_id = aws_api_gateway_rest_api.postboard.id
  resource_id = aws_api_gateway_method.GET__call_random_word.resource_id
  http_method = aws_api_gateway_method.GET__call_random_word.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.call_random_word.invoke_arn
}

resource "aws_lambda_permission" "apigw_invoke_random_word" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.random_word.function_name
  principal     = "apigateway.amazonaws.com"

  # The "/*/*" portion grants access from any method on any resource
  # within the API Gateway REST API.
  source_arn = "${aws_api_gateway_rest_api.postboard.execution_arn}/*/*"
}

resource "aws_lambda_permission" "apigw_invoke_call_random_word" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.call_random_word.function_name
  principal     = "apigateway.amazonaws.com"

  # The "/*/*" portion grants access from any method on any resource
  # within the API Gateway REST API.
  source_arn = "${aws_api_gateway_rest_api.postboard.execution_arn}/*/*"
}

output "base_url" {
  value = aws_api_gateway_deployment.test.invoke_url
}