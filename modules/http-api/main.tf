locals {
  # From staging up, an environment is held to production's rules (see the README).
  upper_stage = contains(["staging", "perf", "prod"], var.stage)
  full_name   = "${var.name}-${var.stage}"
  tags = merge(var.tags, {
    "juniper:app"     = var.name
    "juniper:stage"   = var.stage
    "juniper:module"  = "http-api"
    "juniper:library" = "platform-library"
  })
}

data "aws_iam_policy_document" "assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "fn" {
  name                 = "${local.full_name}-api"
  assume_role_policy   = data.aws_iam_policy_document.assume.json
  permissions_boundary = var.permissions_boundary_arn
  tags                 = local.tags
}

resource "aws_iam_role_policy_attachment" "logs" {
  role       = aws_iam_role.fn.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# In the private network only when the app uses something that lives there, such as a
# database: then the function joins the stage's private subnets and the apps group, and
# its role may make the network interfaces that takes.
locals {
  in_network = length(var.subnet_ids) > 0
}

resource "aws_iam_role_policy_attachment" "network" {
  count      = local.in_network ? 1 : 0
  role       = aws_iam_role.fn.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_cloudwatch_log_group" "fn" {
  name              = "/aws/lambda/${local.full_name}-api"
  retention_in_days = local.upper_stage ? 365 : 7
  tags              = local.tags
}

resource "aws_lambda_function" "fn" {
  function_name    = "${local.full_name}-api"
  role             = aws_iam_role.fn.arn
  runtime          = "nodejs20.x"
  handler          = var.handler
  filename         = var.package_path
  source_code_hash = filebase64sha256(var.package_path)
  tags             = local.tags

  # The platform's default is three seconds, and an app's first request often has to
  # open its connections and make its tables: the front door itself waits thirty.
  # Capacity beyond this is set by a load test, not here.
  timeout     = 30
  memory_size = 256

  environment {
    variables = var.environment
  }

  dynamic "vpc_config" {
    for_each = local.in_network ? [1] : []

    content {
      subnet_ids         = var.subnet_ids
      security_group_ids = var.security_group_ids
    }
  }

  depends_on = [aws_cloudwatch_log_group.fn, aws_iam_role_policy_attachment.network]
}

resource "aws_apigatewayv2_api" "api" {
  name          = local.full_name
  protocol_type = "HTTP"
  tags          = local.tags
}

resource "aws_apigatewayv2_integration" "fn" {
  api_id                 = aws_apigatewayv2_api.api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.fn.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "all" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.fn.id}"
}

# The front door's own record of each request: what was asked, what it answered and how
# long it took, including requests it turned away before they reached the app. No
# caller's address is kept. Under /aws/vendedlogs/, so the account's log resource
# policy covers every app's record with one entry rather than growing with each.
resource "aws_cloudwatch_log_group" "door" {
  name              = "/aws/vendedlogs/apigateway/${local.full_name}-api"
  retention_in_days = local.upper_stage ? 365 : 7
  tags              = local.tags
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = "$default"
  auto_deploy = true
  tags        = local.tags

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.door.arn
    format = jsonencode({
      requestId         = "$context.requestId"
      method            = "$context.httpMethod"
      path              = "$context.path"
      status            = "$context.status"
      latency           = "$context.responseLatency"
      integrationStatus = "$context.integrationStatus"
      integrationError  = "$context.integrationErrorMessage"
      error             = "$context.error.message"
    })
  }
}

resource "aws_lambda_permission" "api" {
  statement_id  = "AllowApiGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.fn.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}

# What the app may read and write, as each module offers it (its access_policy_arn).
resource "aws_iam_role_policy_attachment" "granted" {
  count      = length(var.policy_arns)
  role       = aws_iam_role.fn.name
  policy_arn = var.policy_arns[count.index]
}

data "aws_iam_policy_document" "secrets" {
  count = length(var.secret_arns) > 0 ? 1 : 0

  statement {
    actions   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
    resources = var.secret_arns
  }
}

resource "aws_iam_role_policy" "secrets" {
  count  = length(var.secret_arns) > 0 ? 1 : 0
  name   = "read-secrets"
  role   = aws_iam_role.fn.id
  policy = data.aws_iam_policy_document.secrets[0].json
}
