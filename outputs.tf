output "lambda" {
  value = local.bundle.enabled ? aws_lambda_function.lambda : aws_lambda_function.empty_lambda
}

output "lambda_role" {
  value = aws_iam_role.lambda
}
