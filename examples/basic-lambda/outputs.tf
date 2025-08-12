output "arn" {
  description = "ARN of the Lambda function"
  value       = module.basic_lambda.lambda_function_arn
}

output "name" {
  description = "Name of the Lambda function"
  value       = module.basic_lambda.lambda_function_name
}

output "invoke_arn" {
  description = "Invoke ARN of the Lambda function"
  value       = module.basic_lambda.lambda_function_invoke_arn
}

output "role_arn" {
  description = "ARN of the Lambda execution role"
  value       = module.basic_lambda.lambda_role_arn
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = module.basic_lambda.lambda_cloudwatch_log_group_name
}
