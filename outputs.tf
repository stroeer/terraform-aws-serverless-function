output "lambda" {
  value = aws_lambda_function.lambda
}

output "lambda_role" {
  value = aws_iam_role.lambda
}
