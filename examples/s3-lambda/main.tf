terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = ">= 2.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
module "tags" {
  source  = "sourcefuse/arc-tags/aws"
  version = "1.2.6"

  environment = terraform.workspace
  project     = "terraform-aws-arc-lambda"

  extra_tags = {
    Example = "True"
  }
}

# Create S3 bucket for Lambda deployment packages

module "s3" {
  source  = "sourcefuse/arc-s3/aws"
  version = "0.0.4"

  for_each = var.s3_buckets

  name = each.value.name
  acl  = each.value.acl
  tags = module.tags.tags
}

# Create Lambda deployment package
data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "s3_processor_function.zip"
  source {
    content = templatefile("${path.module}/s3_processor_function.py", {
      source_bucket      = module.s3["bucket2"].bucket_id
      destination_bucket = module.s3["bucket3"].bucket_id
    })
    filename = "lambda_function.py"
  }
}

# Upload Lambda package to S3
resource "aws_s3_object" "lambda_package" {
  bucket = module.s3["bucket1"].bucket_id
  key    = "lambda-packages/${var.function_name}/${data.archive_file.lambda_zip.output_md5}.zip"
  source = data.archive_file.lambda_zip.output_path
  etag   = data.archive_file.lambda_zip.output_md5

  tags = {
    Environment = var.environment
    Function    = var.function_name
  }
}

# Create Lambda function from S3
module "s3_advanced_lambda" {
  source = "../../"

  # Basic configuration
  function_name = var.function_name
  description   = "Advanced Lambda function for S3 file processing with event triggers"
  runtime       = "python3.11"
  handler       = "lambda_function.lambda_handler"
  memory_size   = 512
  timeout       = 300

  # S3 deployment package
  s3_bucket         = module.s3["bucket1"].bucket_id
  s3_key            = aws_s3_object.lambda_package.key
  s3_object_version = aws_s3_object.lambda_package.version_id
  source_code_hash  = data.archive_file.lambda_zip.output_base64sha256

  # Environment variables
  environment_variables = {
    ENVIRONMENT        = var.environment
    LOG_LEVEL          = var.log_level
    SOURCE_BUCKET      = module.s3["bucket2"].bucket_id
    DESTINATION_BUCKET = module.s3["bucket3"].bucket_id
    DEPLOYMENT_BUCKET  = module.s3["bucket1"].bucket_id
    PROCESSING_PREFIX  = var.processing_prefix
  }

  # IAM permissions for comprehensive S3 access
  additional_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess",
    "arn:aws:iam::aws:policy/AmazonSQSFullAccess"
  ]

  # CloudWatch Logs
  create_log_group      = true
  log_retention_in_days = 30

  # Versioning and alias
  publish      = true
  create_alias = true
  alias_name   = var.environment

  # Dead Letter Queue for error handling
  create_dlq                    = true
  dlq_message_retention_seconds = 1209600 # 14 days

  # Lambda Insights for monitoring
  lambda_insights_enabled = var.enable_lambda_insights

  tags = module.tags.tags

  depends_on = [aws_s3_object.lambda_package]
}

# S3 Event Notification to trigger Lambda
resource "aws_s3_bucket_notification" "source_bucket_notification" {
  bucket = module.s3["bucket2"].bucket_id

  lambda_function {
    lambda_function_arn = module.s3_advanced_lambda.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = var.processing_prefix
    filter_suffix       = var.file_extension_filter
  }

  depends_on = [aws_lambda_permission.allow_s3_invoke]
}

# Lambda permission for S3 to invoke the function
resource "aws_lambda_permission" "allow_s3_invoke" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = module.s3_advanced_lambda.name
  principal     = "s3.amazonaws.com"
  source_arn    = module.s3["bucket2"].bucket_arn
}

# CloudWatch Alarm for Lambda errors
resource "aws_cloudwatch_metric_alarm" "lambda_error_alarm" {
  alarm_name          = "${var.function_name}-error-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "This metric monitors lambda errors"
  alarm_actions       = var.sns_topic_arn != "" ? [var.sns_topic_arn] : []

  dimensions = {
    FunctionName = module.s3_advanced_lambda.name
  }

  tags = {
    Environment = var.environment
    Function    = var.function_name
  }
}

# CloudWatch Alarm for Lambda duration
resource "aws_cloudwatch_metric_alarm" "lambda_duration_alarm" {
  alarm_name          = "${var.function_name}-duration-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Average"
  threshold           = "240000" # 4 minutes (function timeout is 5 minutes)
  alarm_description   = "This metric monitors lambda duration"
  alarm_actions       = var.sns_topic_arn != "" ? [var.sns_topic_arn] : []

  dimensions = {
    FunctionName = module.s3_advanced_lambda.name
  }

  tags = {
    Environment = var.environment
    Function    = var.function_name
  }
}
