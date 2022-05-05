output "lambda" {
  value = var.init_empty ? aws_lambda_function.empty_lambda : aws_lambda_function.lambda
}

output "lambda_role" {
  value = aws_iam_role.lambda
}
