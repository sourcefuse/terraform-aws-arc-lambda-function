output "arn" {
  description = "ARN of the Lambda function"
  value       = module.s3_advanced_lambda.arn
}

output "name" {
  description = "Name of the Lambda function"
  value       = module.s3_advanced_lambda.name
}

output "invoke_arn" {
  description = "Invoke ARN of the Lambda function"
  value       = module.s3_advanced_lambda.invoke_arn
}

output "role_arn" {
  description = "ARN of the Lambda execution role"
  value       = module.s3_advanced_lambda.role_arn
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = module.s3_advanced_lambda.cloudwatch_log_group_name
}

output "dead_letter_queue_arn" {
  description = "ARN of the Dead Letter Queue"
  value       = module.s3_advanced_lambda.dead_letter_queue_arn
}

output "alias_arn" {
  description = "ARN of the Lambda alias"
  value       = module.s3_advanced_lambda.alias_arn
}
