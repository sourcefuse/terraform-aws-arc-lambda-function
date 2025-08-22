output "arn" {
  description = "ARN of the Lambda function"
  value       = module.basic_lambda.arn
}

output "name" {
  description = "Name of the Lambda function"
  value       = module.basic_lambda.name
}

output "invoke_arn" {
  description = "Invoke ARN of the Lambda function"
  value       = module.basic_lambda.invoke_arn
}

output "role_arn" {
  description = "ARN of the Lambda execution role"
  value       = module.basic_lambda.role_arn
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = module.basic_lambda.cloudwatch_log_group_name
}
