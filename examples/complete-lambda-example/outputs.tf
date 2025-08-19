# =============================================================================
# LAMBDA FUNCTION OUTPUTS
# =============================================================================

output "arn" {
  description = "ARN of the Lambda function"
  value       = module.complete_lambda.arn
}

output "name" {
  description = "Name of the Lambda function"
  value       = module.complete_lambda.name
}

output "version" {
  description = "Published version of the Lambda function"
  value       = module.complete_lambda.version
}

output "alias_arn" {
  description = "ARN of the Lambda alias"
  value       = module.complete_lambda.alias_arn
}

output "alias_name" {
  description = "Name of the Lambda alias"
  value       = module.complete_lambda.alias_name
}

output "role_arn" {
  description = "ARN of the Lambda execution role"
  value       = module.complete_lambda.role_arn
}

output "url" {
  description = "Lambda function URL (if enabled)"
  value       = var.enable_function_url ? module.complete_lambda.url : null
}


# =============================================================================
# EVENT SOURCES OUTPUTS
# =============================================================================

output "s3_bucket_name" {
  description = "Name of the S3 bucket for event source"
  value       = module.s3.bucket_id
}


# =============================================================================
# MONITORING OUTPUTS
# =============================================================================

output "dead_letter_queue_arn" {
  description = "ARN of the Dead Letter Queue"
  value       = module.complete_lambda.dead_letter_queue_arn
}

output "dead_letter_queue_url" {
  description = "URL of the Dead Letter Queue"
  value       = module.complete_lambda.dead_letter_queue_url
}

output "cloudwatch_dashboard_url" {
  description = "URL to the CloudWatch dashboard"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${var.function_name}-complete-dashboard"
}

output "insights_url" {
  description = "URL to Lambda Insights"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#lambda-insights:functions/${module.complete_lambda.name}"
}
