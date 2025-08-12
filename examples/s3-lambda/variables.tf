variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
  default     = "s3-advanced-processor"
}

variable "deployment_bucket_name" {
  description = "S3 bucket name for Lambda deployment packages (must be globally unique)"
  type        = string
  default     = "lambda-deployments-advanced-example"
}

variable "source_bucket_name" {
  description = "S3 bucket name for source files to be processed (must be globally unique)"
  type        = string
  default     = "s3-source-files-advanced-example"
}

variable "destination_bucket_name" {
  description = "S3 bucket name for processed files (must be globally unique)"
  type        = string
  default     = "s3-processed-files-advanced-example"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "log_level" {
  description = "Log level for the Lambda function"
  type        = string
  default     = "INFO"

  validation {
    condition     = contains(["DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"], var.log_level)
    error_message = "Log level must be one of: DEBUG, INFO, WARNING, ERROR, CRITICAL."
  }
}

variable "processing_prefix" {
  description = "S3 prefix for files to be processed"
  type        = string
  default     = "incoming/"
}

variable "file_extension_filter" {
  description = "File extension filter for S3 events"
  type        = string
  default     = ".txt"
}

variable "enable_lambda_insights" {
  description = "Enable Lambda Insights for enhanced monitoring"
  type        = bool
  default     = true
}

variable "sns_topic_arn" {
  description = "SNS topic ARN for CloudWatch alarms (optional)"
  type        = string
  default     = ""
}
