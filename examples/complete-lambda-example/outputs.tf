# =============================================================================
# LAMBDA FUNCTION OUTPUTS
# =============================================================================

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = module.complete_lambda.lambda_function_arn
}

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = module.complete_lambda.lambda_function_name
}

output "lambda_function_version" {
  description = "Published version of the Lambda function"
  value       = module.complete_lambda.lambda_function_version
}

output "lambda_alias_arn" {
  description = "ARN of the Lambda alias"
  value       = module.complete_lambda.lambda_alias_arn
}

output "lambda_alias_name" {
  description = "Name of the Lambda alias"
  value       = module.complete_lambda.lambda_alias_name
}

output "lambda_role_arn" {
  description = "ARN of the Lambda execution role"
  value       = module.complete_lambda.lambda_role_arn
}

output "lambda_function_url" {
  description = "Lambda function URL (if enabled)"
  value       = var.enable_function_url ? module.complete_lambda.lambda_function_url : null
}



# =============================================================================
# EVENT SOURCES OUTPUTS
# =============================================================================

output "s3_bucket_name" {
  description = "Name of the S3 bucket for event source"
  value       = aws_s3_bucket.event_source.bucket
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket for event source"
  value       = aws_s3_bucket.event_source.arn
}

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

# =============================================================================
# TESTING COMMANDS
# =============================================================================


output "monitoring_commands" {
  description = "Commands for monitoring the Lambda function"
  value = {
    # CloudWatch logs
    view_logs           = "aws logs tail /aws/lambda/${module.complete_lambda.lambda_function_name} --follow"
    view_logs_last_hour = "aws logs filter-log-events --log-group-name /aws/lambda/${module.complete_lambda.lambda_function_name} --start-time $(date -d '1 hour ago' +%s)000"

    # Lambda metrics
    get_invocation_metrics = "aws cloudwatch get-metric-statistics --namespace AWS/Lambda --metric-name Invocations --dimensions Name=FunctionName,Value=${module.complete_lambda.lambda_function_name} --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) --end-time $(date -u +%Y-%m-%dT%H:%M:%S) --period 300 --statistics Sum"
    get_error_metrics      = "aws cloudwatch get-metric-statistics --namespace AWS/Lambda --metric-name Errors --dimensions Name=FunctionName,Value=${module.complete_lambda.lambda_function_name} --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) --end-time $(date -u +%Y-%m-%dT%H:%M:%S) --period 300 --statistics Sum"
    get_duration_metrics   = "aws cloudwatch get-metric-statistics --namespace AWS/Lambda --metric-name Duration --dimensions Name=FunctionName,Value=${module.complete_lambda.lambda_function_name} --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) --end-time $(date -u +%Y-%m-%dT%H:%M:%S) --period 300 --statistics Average,Maximum"

    # Provisioned concurrency metrics
    get_provisioned_concurrency_metrics = "aws cloudwatch get-metric-statistics --namespace AWS/Lambda --metric-name ProvisionedConcurrencyUtilization --dimensions Name=FunctionName,Value=${module.complete_lambda.lambda_function_name} Name=Resource,Value=${module.complete_lambda.lambda_function_name}:${var.alias_name} --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) --end-time $(date -u +%Y-%m-%dT%H:%M:%S) --period 300 --statistics Average,Maximum"

    # DLQ monitoring
    check_dlq_messages   = "aws sqs get-queue-attributes --queue-url ${module.complete_lambda.lambda_dead_letter_queue_url} --attribute-names ApproximateNumberOfMessages"
    receive_dlq_messages = "aws sqs receive-message --queue-url ${module.complete_lambda.lambda_dead_letter_queue_url} --max-number-of-messages 10"

    # Function configuration
    get_function_config        = "aws lambda get-function --function-name ${module.complete_lambda.lambda_function_name}"
    get_alias_config           = "aws lambda get-alias --function-name ${module.complete_lambda.lambda_function_name} --name ${var.alias_name}"
    list_event_source_mappings = "aws lambda list-event-source-mappings --function-name ${module.complete_lambda.lambda_function_name}"
  }
}
