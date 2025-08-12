# =============================================================================
# LAMBDA FUNCTION OUTPUTS
# =============================================================================

output "lambda_function_arn" {
  description = "The Amazon Resource Name (ARN) identifying your Lambda Function"
  value       = aws_lambda_function.this.arn
}

output "lambda_function_name" {
  description = "The name of the Lambda Function"
  value       = aws_lambda_function.this.function_name
}

output "lambda_function_qualified_arn" {
  description = "The Amazon Resource Name (ARN) identifying your Lambda Function Version"
  value       = aws_lambda_function.this.qualified_arn
}

output "lambda_function_version" {
  description = "Latest published version of your Lambda Function"
  value       = aws_lambda_function.this.version
}

output "lambda_function_last_modified" {
  description = "The date this resource was last modified"
  value       = aws_lambda_function.this.last_modified
}

output "lambda_function_kms_key_arn" {
  description = "The ARN of the KMS Key used to encrypt your Lambda Function's environment variables"
  value       = aws_lambda_function.this.kms_key_arn
}

output "lambda_function_source_code_hash" {
  description = "Base64-encoded representation of raw SHA-256 sum of the zip file"
  value       = aws_lambda_function.this.source_code_hash
}

output "lambda_function_source_code_size" {
  description = "The size in bytes of the function .zip file"
  value       = aws_lambda_function.this.source_code_size
}

output "lambda_function_invoke_arn" {
  description = "The ARN to be used for invoking Lambda Function from API Gateway"
  value       = aws_lambda_function.this.invoke_arn
}

output "lambda_function_signing_job_arn" {
  description = "ARN of the signing job"
  value       = aws_lambda_function.this.signing_job_arn
}

output "lambda_function_signing_profile_version_arn" {
  description = "ARN of the signing profile version"
  value       = aws_lambda_function.this.signing_profile_version_arn
}

# =============================================================================
# IAM ROLE OUTPUTS
# =============================================================================

output "lambda_role_arn" {
  description = "The Amazon Resource Name (ARN) specifying the Lambda IAM role"
  value       = local.lambda_role_arn
}

output "lambda_role_name" {
  description = "The name of the Lambda IAM role"
  value       = local.create_new_role ? aws_iam_role.lambda[0].name : null
}

output "lambda_role_unique_id" {
  description = "The stable and unique string identifying the Lambda IAM role"
  value       = local.create_new_role ? aws_iam_role.lambda[0].unique_id : null
}

# =============================================================================
# CLOUDWATCH LOG GROUP OUTPUTS
# =============================================================================

output "lambda_cloudwatch_log_group_name" {
  description = "The name of the CloudWatch Log Group"
  value       = var.create_log_group ? aws_cloudwatch_log_group.lambda[0].name : null
}

output "lambda_cloudwatch_log_group_arn" {
  description = "The Amazon Resource Name (ARN) specifying the log group"
  value       = var.create_log_group ? aws_cloudwatch_log_group.lambda[0].arn : null
}

# =============================================================================
# DEAD LETTER QUEUE OUTPUTS
# =============================================================================

output "lambda_dead_letter_queue_arn" {
  description = "The ARN of the SQS queue used as dead letter queue"
  value       = var.create_dlq ? aws_sqs_queue.dlq[0].arn : null
}

output "lambda_dead_letter_queue_name" {
  description = "The name of the SQS queue used as dead letter queue"
  value       = var.create_dlq ? aws_sqs_queue.dlq[0].name : null
}

output "lambda_dead_letter_queue_url" {
  description = "The URL of the SQS queue used as dead letter queue"
  value       = var.create_dlq ? aws_sqs_queue.dlq[0].url : null
}

# =============================================================================
# LAMBDA ALIAS OUTPUTS
# =============================================================================

output "lambda_alias_arn" {
  description = "The Amazon Resource Name (ARN) identifying the Lambda function alias"
  value       = var.create_alias ? aws_lambda_alias.this[0].arn : null
}

output "lambda_alias_name" {
  description = "The name of the Lambda function alias"
  value       = var.create_alias ? aws_lambda_alias.this[0].name : null
}

output "lambda_alias_description" {
  description = "Description of the Lambda function alias"
  value       = var.create_alias ? aws_lambda_alias.this[0].description : null
}

output "lambda_alias_function_version" {
  description = "Lambda function version which the alias uses"
  value       = var.create_alias ? aws_lambda_alias.this[0].function_version : null
}

output "lambda_alias_invoke_arn" {
  description = "The ARN to be used for invoking Lambda Function alias from API Gateway"
  value       = var.create_alias ? aws_lambda_alias.this[0].invoke_arn : null
}

# =============================================================================
# PROVISIONED CONCURRENCY OUTPUTS
# =============================================================================

output "lambda_provisioned_concurrency_config_id" {
  description = "The ID of the provisioned concurrency configuration"
  value       = var.provisioned_concurrency_config != null ? aws_lambda_provisioned_concurrency_config.this[0].id : null
}

# =============================================================================
# LAMBDA FUNCTION URL OUTPUTS
# =============================================================================

output "lambda_function_url" {
  description = "The HTTP URL endpoint for the Lambda function"
  value       = var.create_function_url ? aws_lambda_function_url.this[0].function_url : null
}

output "lambda_function_url_id" {
  description = "The generated ID for the endpoint"
  value       = var.create_function_url ? aws_lambda_function_url.this[0].url_id : null
}

# =============================================================================
# COMPUTED VALUES OUTPUTS
# =============================================================================

output "lambda_function_environment_variables" {
  description = "The Lambda function environment variables"
  value       = var.environment_variables
  sensitive   = true
}

output "lambda_function_vpc_config" {
  description = "The Lambda function VPC configuration"
  value = local.vpc_config_enabled ? {
    subnet_ids         = var.vpc_config.subnet_ids
    security_group_ids = var.vpc_config.security_group_ids
    vpc_id             = aws_lambda_function.this.vpc_config[0].vpc_id
  } : null
}

output "lambda_function_tags" {
  description = "The Lambda function tags"
  value       = local.function_tags
}
