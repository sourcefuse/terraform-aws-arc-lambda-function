# =============================================================================
# LAMBDA FUNCTION OUTPUTS
# =============================================================================

output "arn" {
  description = "ARN of the Lambda function"
  value       = module.complete_lambda.lambda_function_arn
}

output "name" {
  description = "Name of the Lambda function"
  value       = module.complete_lambda.lambda_function_name
}

output "version" {
  description = "Published version of the Lambda function"
  value       = module.complete_lambda.lambda_function_version
}

output "alias_arn" {
  description = "ARN of the Lambda alias"
  value       = module.complete_lambda.lambda_alias_arn
}

output "alias_name" {
  description = "Name of the Lambda alias"
  value       = module.complete_lambda.lambda_alias_name
}

output "role_arn" {
  description = "ARN of the Lambda execution role"
  value       = module.complete_lambda.lambda_role_arn
}

output "url" {
  description = "Lambda function URL (if enabled)"
  value       = var.enable_function_url ? module.complete_lambda.lambda_function_url : null
}



# =============================================================================
# EVENT SOURCES OUTPUTS
# =============================================================================

output "s3_bucket_name" {
  description = "Name of the S3 bucket for event source"
  value       = module.s3.bucket_id
}

# output "s3_bucket_arn" {
#   description = "ARN of the S3 bucket for event source"
#   value       = aws_s3_bucket.event_source.arn
# }

output "sns_topic_arn" {
  description = "ARN of the SNS topic"
  value       = aws_sns_topic.lambda_notifications.arn
}

output "sqs_queue_url" {
  description = "URL of the SQS queue"
  value       = aws_sqs_queue.lambda_queue.url
}

output "sqs_queue_arn" {
  description = "ARN of the SQS queue"
  value       = aws_sqs_queue.lambda_queue.arn
}

output "api_gateway_url" {
  description = "URL of the API Gateway endpoint"
  value       = "https://${aws_api_gateway_rest_api.lambda_api.id}.execute-api.${var.aws_region}.amazonaws.com/${var.api_stage_name}/lambda"
}

output "api_gateway_rest_api_id" {
  description = "ID of the API Gateway REST API"
  value       = aws_api_gateway_rest_api.lambda_api.id
}

output "eventbridge_rule_name" {
  description = "Name of the EventBridge rule"
  value       = aws_cloudwatch_event_rule.lambda_schedule.name
}

# =============================================================================
# MONITORING OUTPUTS
# =============================================================================

output "dead_letter_queue_arn" {
  description = "ARN of the Dead Letter Queue"
  value       = module.complete_lambda.lambda_dead_letter_queue_arn
}

output "dead_letter_queue_url" {
  description = "URL of the Dead Letter Queue"
  value       = module.complete_lambda.lambda_dead_letter_queue_url
}

output "cloudwatch_dashboard_url" {
  description = "URL to the CloudWatch dashboard"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${var.function_name}-complete-dashboard"
}

output "lambda_insights_url" {
  description = "URL to Lambda Insights"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#lambda-insights:functions/${module.complete_lambda.lambda_function_name}"
}

# =============================================================================
# SECURITY OUTPUTS
# =============================================================================

output "kms_key_id" {
  description = "ID of the KMS key used for encryption"
  value       = aws_kms_key.lambda_key.key_id
}

output "kms_key_arn" {
  description = "ARN of the KMS key used for encryption"
  value       = aws_kms_key.lambda_key.arn
}

output "ssm_parameter_names" {
  description = "Names of the created SSM parameters"
  value       = [for param in aws_ssm_parameter.lambda_config : param.name]
}
