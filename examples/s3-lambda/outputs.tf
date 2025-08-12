output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = module.s3_advanced_lambda.lambda_function_arn
}

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = module.s3_advanced_lambda.lambda_function_name
}

output "lambda_function_invoke_arn" {
  description = "Invoke ARN of the Lambda function"
  value       = module.s3_advanced_lambda.lambda_function_invoke_arn
}

output "lambda_role_arn" {
  description = "ARN of the Lambda execution role"
  value       = module.s3_advanced_lambda.lambda_role_arn
}

output "lambda_cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = module.s3_advanced_lambda.lambda_cloudwatch_log_group_name
}

output "lambda_dead_letter_queue_arn" {
  description = "ARN of the Dead Letter Queue"
  value       = module.s3_advanced_lambda.lambda_dead_letter_queue_arn
}

output "deployment_bucket_name" {
  description = "Name of the S3 bucket for Lambda deployments"
  value       = aws_s3_bucket.lambda_deployments.bucket
}

output "deployment_bucket_arn" {
  description = "ARN of the S3 bucket for Lambda deployments"
  value       = aws_s3_bucket.lambda_deployments.arn
}

output "source_bucket_name" {
  description = "Name of the S3 source bucket"
  value       = aws_s3_bucket.source_bucket.bucket
}

output "source_bucket_arn" {
  description = "ARN of the S3 source bucket"
  value       = aws_s3_bucket.source_bucket.arn
}

output "destination_bucket_name" {
  description = "Name of the S3 destination bucket"
  value       = aws_s3_bucket.destination_bucket.bucket
}

output "destination_bucket_arn" {
  description = "ARN of the S3 destination bucket"
  value       = aws_s3_bucket.destination_bucket.arn
}

output "lambda_package_s3_key" {
  description = "S3 key of the Lambda deployment package"
  value       = aws_s3_object.lambda_package.key
}

output "lambda_alias_arn" {
  description = "ARN of the Lambda alias"
  value       = module.s3_advanced_lambda.lambda_alias_arn
}

output "cloudwatch_error_alarm_arn" {
  description = "ARN of the CloudWatch error alarm"
  value       = aws_cloudwatch_metric_alarm.lambda_error_alarm.arn
}

output "cloudwatch_duration_alarm_arn" {
  description = "ARN of the CloudWatch duration alarm"
  value       = aws_cloudwatch_metric_alarm.lambda_duration_alarm.arn
}
