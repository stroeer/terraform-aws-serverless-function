output "lambda" {
  value = var.bundle.enabled ? aws_lambda_function.lambda[0] : aws_lambda_function.empty_lambda[0]
}

output "lambda_role" {
  value = aws_iam_role.lambda
}
