# AWS Configuration
aws_region = "us-east-1"

# Lambda Function Configuration
function_name = "s3-advanced-processor"
environment   = "dev"
log_level     = "INFO"

# S3 Bucket Names (must be globally unique - change these!)

s3_buckets = {
  bucket1 = {
    name = "your-unique-lambda-deployments-advanced-bucket"
    acl  = "private"
  }
  bucket2 = {
    name = "your-unique-source-files-advanced-bucket"
    acl  = "private"
  }
  bucket3 = {
    name = "your-unique-processed-files-advanced-bucket"
    acl  = "private"
  }
}

# File Processing Configuration
processing_prefix     = "incoming/"
file_extension_filter = ".txt"

# Monitoring Configuration
enable_lambda_insights = true
