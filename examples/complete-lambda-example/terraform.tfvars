# =============================================================================
# COMPLETE LAMBDA EXAMPLE CONFIGURATION
# This file demonstrates ALL features of the Lambda Terraform module
# =============================================================================
region      = "us-east-1"
environment = "develop"
namespace   = "arc"
# Basic Configuration
aws_region       = "us-east-1"
function_name    = "complete-lambda-example"
function_version = "1.0.0"
log_level        = "INFO"

# Lambda Function Configuration
memory_size = 1024 # Higher memory for better performance
timeout     = 60   # Longer timeout for complex operations

# Database Configuration
db_password = "CompleteExample2024!" # Change this for production use

# S3 Configuration (MUST be globally unique)
s3_bucket_name = "complete-lambda-example-bucket-12345" # Change this to a unique name

# Dead Letter Queue Configuration
dlq_retention_seconds = 1209600 # 14 days

alias_name                        = "production"
provisioned_concurrent_executions = 5

# API Gateway Configuration
api_stage_name = "prod"

# EventBridge Configuration (Scheduled invocations)
schedule_expression = "rate(10 minutes)" # Every 10 minutes

# Function URL Configuration (Direct HTTPS access)
enable_function_url = true

# CloudWatch Configuration
log_retention_days = 30 # 30 days for production

# Notification Configuration (Optional - add your email for alerts)
notification_email = "" # Add your email here: "your-email@example.com"

# SSM Parameters Configuration (Demonstrates parameter store integration)
ssm_parameters = {
  # Configuration parameters
  "config/max_retries" = {
    type  = "String"
    value = "5"
  }
  "config/timeout_seconds" = {
    type  = "String"
    value = "30"
  }
  "config/batch_size" = {
    type  = "String"
    value = "10"
  }
  "config/debug_mode" = {
    type  = "String"
    value = "false"
  }
  "config/enable_metrics" = {
    type  = "String"
    value = "true"
  }

  # Secret parameters (encrypted)
  "secrets/api_key" = {
    type  = "SecureString"
    value = "complete-example-api-key-12345"
  }
  "secrets/db_connection_string" = {
    type  = "SecureString"
    value = "postgresql://dbadmin:password@localhost:5432/lambdadb"
  }

  # Feature flags
  "features/enable_s3_processing" = {
    type  = "String"
    value = "true"
  }
  "features/enable_sns_notifications" = {
    type  = "String"
    value = "true"
  }
  "features/enable_database_logging" = {
    type  = "String"
    value = "true"
  }
  "features/enable_advanced_monitoring" = {
    type  = "String"
    value = "true"
  }
  "features/enable_performance_optimization" = {
    type  = "String"
    value = "true"
  }
}
