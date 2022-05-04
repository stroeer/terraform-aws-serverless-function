locals {
  lambda_name = "${var.prefix}${var.name}${var.suffix}"
  logs = defaults(var.logs, {
    enabled = false,
    retention = 30
  })
  source_file = var.init_empty ? "README.md" : "${var.artifact_folder}/${var.name}"
}

data "archive_file" "code" {
  type        = "zip"
  source_file = local.source_file
  output_path = "${var.name}.zip"
}

data "aws_iam_policy_document" "lambda_assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "lambda_policies" {
  count                     = length(var.inline_policies) == 0 ? 0 : 1
  override_policy_documents = var.inline_policies
}

resource "aws_iam_role" "lambda" {
  name               = "${local.lambda_name}-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "lambda_policies" {
  for_each   = var.managed_policies
  policy_arn = each.value
  role       = aws_iam_role.lambda.name
}

resource "aws_iam_role_policy" "lambda_policies" {
  count  = length(var.inline_policies) == 0 ? 0 : 1
  name   = "${local.lambda_name}-policies"
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.lambda_policies[0].json
}

resource "aws_lambda_function" "lambda" {
  description      = "The lambda function which executes your code."
  function_name    = local.lambda_name
  runtime          = var.runtime
  memory_size      = var.memory
  filename         = data.archive_file.code.output_path
  source_code_hash = data.archive_file.code.output_base64sha256
  handler          = var.name
  timeout          = var.timeout
  role             = aws_iam_role.lambda.arn
  dynamic "environment" {
    for_each = length(var.environment_vars) > 0 ? [1] : []
    content {
      variables = var.environment_vars
    }
  }
  depends_on = [
    data.archive_file.code,
    aws_iam_role_policy_attachment.lambda_logs,
    aws_cloudwatch_log_group.lambda,
  ]
  lifecycle {
    ignore_changes = var.init_empty ? [filename, source_code_hash] : []
  }
}

resource "aws_cloudwatch_log_group" "lambda" {
  count = local.logs.enabled ? 1 : 0
  name = "/aws/lambda/${local.lambda_name}"
  retention_in_days = local.logs.retention
}

data "aws_iam_policy" "logging_policy" {
  count = local.logs.enabled ? 1 : 0
  name = "AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  count = local.logs.enabled ? 1 : 0
  policy_arn = data.aws_iam_policy.logging_policy[0].arn
  role       = aws_iam_role.lambda.name
}
