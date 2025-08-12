# AWS Configuration
aws_region = "us-east-1"

# Lambda Function Configuration
function_name = "s3-advanced-processor"
environment   = "dev"
log_level     = "INFO"

# S3 Bucket Names (must be globally unique - change these!)
deployment_bucket_name  = "your-unique-lambda-deployments-advanced-bucket"
source_bucket_name      = "your-unique-source-files-advanced-bucket"
destination_bucket_name = "your-unique-processed-files-advanced-bucket"

# File Processing Configuration
processing_prefix     = "incoming/"
file_extension_filter = ".txt"

# Monitoring Configuration
enable_lambda_insights = true
