# =============================================================================
# LAMBDA FUNCTION OUTPUTS
# =============================================================================

output "arn" {
  description = "The Amazon Resource Name (ARN) identifying your Lambda Function"
  value       = aws_lambda_function.this.arn
}

output "name" {
  description = "The name of the Lambda Function"
  value       = aws_lambda_function.this.function_name
}

output "qualified_arn" {
  description = "The Amazon Resource Name (ARN) identifying your Lambda Function Version"
  value       = aws_lambda_function.this.qualified_arn
}

output "version" {
  description = "Latest published version of your Lambda Function"
  value       = aws_lambda_function.this.version
}

output "last_modified" {
  description = "The date this resource was last modified"
  value       = aws_lambda_function.this.last_modified
}

output "kms_key_arn" {
  description = "The ARN of the KMS Key used to encrypt your Lambda Function's environment variables"
  value       = aws_lambda_function.this.kms_key_arn
}

output "source_code_size" {
  description = "The size in bytes of the function .zip file"
  value       = aws_lambda_function.this.source_code_size
}

output "invoke_arn" {
  description = "The ARN to be used for invoking Lambda Function from API Gateway"
  value       = aws_lambda_function.this.invoke_arn
}

output "signing_job_arn" {
  description = "ARN of the signing job"
  value       = aws_lambda_function.this.signing_job_arn
}

output "signing_profile_version_arn" {
  description = "ARN of the signing profile version"
  value       = aws_lambda_function.this.signing_profile_version_arn
}

output "role_arn" {
  description = "ARN of the IAM role used by the Lambda function. If an existing role ARN is provided via var.role_arn, it is used; otherwise, the default role created in this module is returned."
  value       = var.role_arn != null ? var.role_arn : aws_iam_role.default[0].arn
}
# =============================================================================
# CLOUDWATCH LOG GROUP OUTPUTS
# =============================================================================

output "cloudwatch_log_group_name" {
  description = "The name of the CloudWatch Log Group"
  value       = var.create_log_group ? aws_cloudwatch_log_group.lambda[0].name : null
}

output "cloudwatch_log_group_arn" {
  description = "The Amazon Resource Name (ARN) specifying the log group"
  value       = var.create_log_group ? aws_cloudwatch_log_group.lambda[0].arn : null
}

# =============================================================================
# DEAD LETTER QUEUE OUTPUTS
# =============================================================================

output "dead_letter_queue_arn" {
  description = "The ARN of the SQS queue used as dead letter queue"
  value       = var.create_dlq ? aws_sqs_queue.dlq[0].arn : null
}

output "dead_letter_queue_name" {
  description = "The name of the SQS queue used as dead letter queue"
  value       = var.create_dlq ? aws_sqs_queue.dlq[0].name : null
}

output "dead_letter_queue_url" {
  description = "The URL of the SQS queue used as dead letter queue"
  value       = var.create_dlq ? aws_sqs_queue.dlq[0].url : null
}

# =============================================================================
# LAMBDA ALIAS OUTPUTS
# =============================================================================

output "alias_arn" {
  description = "The Amazon Resource Name (ARN) identifying the Lambda function alias"
  value       = var.create_alias ? aws_lambda_alias.this[0].arn : null
}

output "alias_name" {
  description = "The name of the Lambda function alias"
  value       = var.create_alias ? aws_lambda_alias.this[0].name : null
}

output "alias_description" {
  description = "Description of the Lambda function alias"
  value       = var.create_alias ? aws_lambda_alias.this[0].description : null
}

output "alias_function_version" {
  description = "Lambda function version which the alias uses"
  value       = var.create_alias ? aws_lambda_alias.this[0].function_version : null
}

output "alias_invoke_arn" {
  description = "The ARN to be used for invoking Lambda Function alias from API Gateway"
  value       = var.create_alias ? aws_lambda_alias.this[0].invoke_arn : null
}

# =============================================================================
# PROVISIONED CONCURRENCY OUTPUTS
# =============================================================================

output "provisioned_concurrency_config_id" {
  description = "The ID of the provisioned concurrency configuration"
  value       = var.provisioned_concurrency_config != null ? aws_lambda_provisioned_concurrency_config.this[0].id : null
}

# =============================================================================
# LAMBDA FUNCTION URL OUTPUTS
# =============================================================================

output "url" {
  description = "The HTTP URL endpoint for the Lambda function"
  value       = var.create_function_url ? aws_lambda_function_url.this[0].function_url : null
}

output "url_id" {
  description = "The generated ID for the endpoint"
  value       = var.create_function_url ? aws_lambda_function_url.this[0].url_id : null
}

# =============================================================================
# COMPUTED VALUES OUTPUTS
# =============================================================================

output "environment_variables" {
  description = "The Lambda function environment variables"
  value       = var.environment_variables
  sensitive   = true
}

output "vpc_config" {
  description = "The Lambda function VPC configuration"
  value = local.vpc_config_enabled ? {
    subnet_ids         = var.vpc_config.subnet_ids
    security_group_ids = var.vpc_config.security_group_ids
    vpc_id             = aws_lambda_function.this.vpc_config[0].vpc_id
  } : null
}
