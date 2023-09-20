locals {
  lambda_name = "${var.prefix}${var.name}${var.suffix}"

  bundled_source = var.type == "go" ? "${var.bundle.source_folder}/bootstrap" : var.bundle.source_folder
  empty_source   = "${path.module}/README.md"
  source         = var.bundle.enabled ? local.bundled_source : local.empty_source
  inVpc = var.vpc != null ? 1 : 0
  
  latest_runtimes = {
    "go" : "provided.al2",
    "node" : "nodejs16.x",
    "python" : "python3.9",
    "ruby" : "ruby3.2",
    "java" : "java11",
    ".net" : "dotnet6",
    "custom" : "provided.al2"
  }
  runtime = local.latest_runtimes[var.type]

  handlers = {
    "go" : "bootstrap"
    "node" : "index.handler"
    "custom" : "bootstrap"
  }
  handler      = var.handler != null ? var.handler : local.handlers[var.type]
  architecture = var.type == "go" ? ["x86_64"] : ["arm64"]
}

data "archive_file" "code" {
  type        = "zip"
  source_file = var.type == "go" ? local.source : null
  source_dir  = var.type == "go" ? null : local.source
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
  count            = var.bundle.enabled ? 1 : 0
  description      = var.description
  function_name    = local.lambda_name
  runtime          = local.runtime
  memory_size      = var.memory
  filename         = data.archive_file.code.output_path
  source_code_hash = data.archive_file.code.output_base64sha256
  handler          = local.handler
  timeout          = var.timeout
  role             = aws_iam_role.lambda.arn
  architectures    = local.architecture

  dynamic "vpc_config" {
    for_each = range(local.inVpc)
    content {
      subnet_ids         = var.vpc.subnet_ids
      security_group_ids = var.vpc.security_group_ids
    }
  }

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
}

resource "aws_lambda_function" "empty_lambda" {
  count            = var.bundle.enabled ? 0 : 1
  description      = var.description
  function_name    = local.lambda_name
  runtime          = local.runtime
  memory_size      = var.memory
  filename         = data.archive_file.code.output_path
  source_code_hash = data.archive_file.code.output_base64sha256
  handler          = local.handler
  timeout          = var.timeout
  role             = aws_iam_role.lambda.arn

  dynamic "vpc_config" {
    for_each = range(local.inVpc)
    content {
      subnet_ids         = var.vpc.subnet_ids
      security_group_ids = var.vpc.security_group_ids
    }
  }

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
    ignore_changes = [
      filename,
    source_code_hash]
  }
}

resource "aws_cloudwatch_log_group" "lambda" {
  count             = var.logs.enabled ? 1 : 0
  name              = "/aws/lambda/${local.lambda_name}"
  retention_in_days = var.logs.retention
}

data "aws_iam_policy" "logging_policy" {
  count = var.logs.enabled ? 1 : 0
  name  = "AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  count      = var.logs.enabled ? 1 : 0
  policy_arn = data.aws_iam_policy.logging_policy[0].arn
  role       = aws_iam_role.lambda.name
}
