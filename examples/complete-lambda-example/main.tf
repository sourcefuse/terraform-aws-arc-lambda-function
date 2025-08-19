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

# =============================================================================
# VPC INFRASTRUCTURE
# =============================================================================

###################################################################
#                Security Group
###################################################################
module "arc_security_group" {
  source  = "sourcefuse/arc-security-group/aws"
  version = "0.0.1"

  name          = "${var.namespace}-${var.environment}-${var.function_name}-sg"
  vpc_id        = data.aws_vpc.default.id
  ingress_rules = local.security_group_data.ingress_rules
  egress_rules  = local.security_group_data.egress_rules

  tags = module.tags.tags
}

module "rds" {
  source  = "sourcefuse/arc-db/aws"
  version = "4.0.1"

  environment = var.environment
  namespace   = var.namespace
  vpc_id      = data.aws_vpc.this.id

  name                 = "${var.namespace}-${var.environment}-test"
  engine_type          = "rds"
  db_server_class      = "db.t3.small"
  port                 = 5432
  username             = "postgres"
  manage_user_password = true
  engine               = "postgres"
  engine_version       = "16.3"

  license_model = "postgresql-license"
  db_subnet_group_data = {
    name        = "${var.namespace}-${var.environment}-subnet-group"
    create      = true
    description = "Subnet group for rds instance"
    subnet_ids  = data.aws_subnets.private.ids
  }

  security_group_data          = local.rds_security_group_data
  performance_insights_enabled = true
  monitoring_interval          = 5

  kms_data = {
    create                  = true
    description             = "KMS for Performance insight and storage"
    deletion_window_in_days = 7
    enable_key_rotation     = true
  }
}
# =============================================================================
# S3 BUCKET FOR EVENT SOURCE
# =============================================================================

# resource "aws_s3_bucket" "event_source" {
#   bucket = var.s3_bucket_name

#   tags = {
#     Environment = var.environment
#     Project     = "lambda-terraform-module"
#     Purpose     = "lambda-event-source"
#   }
# }

# resource "aws_s3_bucket_versioning" "event_source" {
#   bucket = aws_s3_bucket.event_source.id
#   versioning_configuration {
#     status = "Enabled"
#   }
# }

# resource "aws_s3_bucket_server_side_encryption_configuration" "event_source" {
#   bucket = aws_s3_bucket.event_source.id

#   rule {
#     apply_server_side_encryption_by_default {
#       sse_algorithm = "AES256"
#     }
#   }
# }

# resource "aws_s3_bucket_public_access_block" "event_source" {
#   bucket = aws_s3_bucket.event_source.id

#   block_public_acls       = true
#   block_public_policy     = true
#   ignore_public_acls      = true
#   restrict_public_buckets = true
# }
module "s3" {
  source  = "sourcefuse/arc-s3/aws"
  version = "0.0.4"

  name = var.s3_bucket_name
  acl  = var.acl
  tags = module.tags.tags
}
# =============================================================================
# SNS TOPIC FOR NOTIFICATIONS
# =============================================================================

resource "aws_sns_topic" "lambda_notifications" {
  name = "${var.function_name}-notifications"

  tags = {
    Environment = var.environment
    Project     = "lambda-terraform-module"
  }
}

resource "aws_sns_topic_subscription" "email_notification" {
  count = var.notification_email != "" ? 1 : 0

  topic_arn = aws_sns_topic.lambda_notifications.arn
  protocol  = "email"
  endpoint  = var.notification_email
}

# =============================================================================
# SQS QUEUE FOR EVENT PROCESSING
# =============================================================================

resource "aws_sqs_queue" "lambda_queue" {
  name                       = "${var.function_name}-queue"
  message_retention_seconds  = 1209600 # 14 days
  visibility_timeout_seconds = 300     # 5 minutes

  tags = {
    Environment = var.environment
    Project     = "lambda-terraform-module"
  }
}

# =============================================================================
# API GATEWAY
# =============================================================================

resource "aws_api_gateway_rest_api" "lambda_api" {
  name        = "${var.function_name}-api"
  description = "API Gateway for complete Lambda example"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = {
    Environment = var.environment
    Project     = "lambda-terraform-module"
  }
}

resource "aws_api_gateway_resource" "lambda_resource" {
  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  parent_id   = aws_api_gateway_rest_api.lambda_api.root_resource_id
  path_part   = "lambda"
}

resource "aws_api_gateway_method" "lambda_method" {
  rest_api_id   = aws_api_gateway_rest_api.lambda_api.id
  resource_id   = aws_api_gateway_resource.lambda_resource.id
  http_method   = "POST"
  authorization = "AWS_IAM"
}

resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  resource_id = aws_api_gateway_resource.lambda_resource.id
  http_method = aws_api_gateway_method.lambda_method.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = module.complete_lambda.lambda_function_invoke_arn
}

resource "aws_api_gateway_deployment" "lambda_deployment" {
  depends_on = [
    aws_api_gateway_integration.lambda_integration,
  ]

  rest_api_id = aws_api_gateway_rest_api.lambda_api.id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "lambda_stage" {
  deployment_id        = aws_api_gateway_deployment.lambda_deployment.id
  rest_api_id          = aws_api_gateway_rest_api.lambda_api.id
  stage_name           = var.api_stage_name
  xray_tracing_enabled = false # Sensitive

  tags = {
    Environment = var.environment
    Project     = "lambda-terraform-module"
  }
}

# =============================================================================
# EVENTBRIDGE RULE
# =============================================================================

resource "aws_cloudwatch_event_rule" "lambda_schedule" {
  name                = "${var.function_name}-schedule"
  description         = "Scheduled trigger for Lambda function"
  schedule_expression = var.schedule_expression

  tags = {
    Environment = var.environment
    Project     = "lambda-terraform-module"
  }
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.lambda_schedule.name
  target_id = "LambdaTarget"
  arn       = module.complete_lambda.lambda_alias_arn != null ? module.complete_lambda.lambda_alias_arn : module.complete_lambda.lambda_function_arn

  input = jsonencode({
    source      = "eventbridge"
    rule_name   = aws_cloudwatch_event_rule.lambda_schedule.name
    description = "Scheduled invocation"
  })
}

# =============================================================================
# KMS KEY FOR ENCRYPTION
# =============================================================================

resource "aws_kms_key" "lambda_key" {
  description             = "KMS key for Lambda function encryption"
  deletion_window_in_days = 7

  tags = {
    Name        = "${var.function_name}-kms-key"
    Environment = var.environment
    Project     = "lambda-terraform-module"
  }
}

resource "aws_kms_alias" "lambda_key_alias" {
  name          = "alias/${var.function_name}-key"
  target_key_id = aws_kms_key.lambda_key.key_id
}

# =============================================================================
# SSM PARAMETERS
# =============================================================================

resource "aws_ssm_parameter" "lambda_config" {
  for_each = var.ssm_parameters

  name  = "/${var.function_name}/${each.key}"
  type  = each.value.type
  value = each.value.value

  tags = {
    Environment = var.environment
    Project     = "lambda-terraform-module"
    Function    = var.function_name
  }
}

# =============================================================================
# LAMBDA FUNCTION CODE
# =============================================================================

data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "lambda_function.zip"
  source {
    content = templatefile("${path.module}/lambda_function.py", {
      s3_bucket_name = module.s3.bucket_id
      sns_topic_arn  = aws_sns_topic.lambda_notifications.arn
      sqs_queue_url  = aws_sqs_queue.lambda_queue.url
      db_endpoint    = module.rds.endpoint
      vpc_id         = data.aws_vpc.default.id
    })
    filename = "lambda_function.py"
  }
}

# =============================================================================
# COMPLETE LAMBDA FUNCTION WITH ALL FEATURES
# =============================================================================

module "complete_lambda" {
  source = "../../"

  # Basic configuration
  function_name = var.function_name
  description   = "Complete Lambda function demonstrating all features: VPC, DLQ, Alias, Provisioned Concurrency, Permissions, and more"
  runtime       = "python3.11"
  handler       = "lambda_function.lambda_handler"
  memory_size   = var.memory_size
  timeout       = var.timeout
  architectures = ["arm64"] # Better price-performance

  # Deployment package
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  # Enable versioning and publishing
  publish = true

  # Environment variables with KMS encryption
  environment_variables = {
    ENVIRONMENT      = var.environment
    LOG_LEVEL        = var.log_level
    S3_BUCKET_NAME   = module.s3.bucket_id
    SNS_TOPIC_ARN    = aws_sns_topic.lambda_notifications.arn
    SQS_QUEUE_URL    = aws_sqs_queue.lambda_queue.url
    DB_ENDPOINT      = module.rds.endpoint
    DB_NAME          = module.rds.id
    DB_USERNAME      = module.rds.username
    VPC_ID           = data.aws_vpc.default.id
    API_GATEWAY_URL  = "https://${aws_api_gateway_rest_api.lambda_api.id}.execute-api.${var.aws_region}.amazonaws.com/${var.api_stage_name}"
    FUNCTION_VERSION = var.function_version
  }
  kms_key_arn = aws_kms_key.lambda_key.arn

  # VPC configuration
  vpc_config = {
    subnet_ids         = [data.aws_subnets.private.ids[0]]
    security_group_ids = [module.arc_security_group.id]
  }

  # Dead Letter Queue
  create_dlq                    = true
  dlq_message_retention_seconds = var.dlq_retention_seconds

  # Create alias for blue-green deployments
  create_alias      = true
  alias_name        = var.alias_name
  alias_description = "Production alias for complete Lambda example"


  # Lambda permissions for all event sources
  lambda_permissions = {
    api_gateway = {
      action     = "lambda:InvokeFunction"
      principal  = "apigateway.amazonaws.com"
      source_arn = "${aws_api_gateway_rest_api.lambda_api.execution_arn}/*/*"
    }
    s3_trigger = {
      action     = "lambda:InvokeFunction"
      principal  = "s3.amazonaws.com"
      source_arn = module.s3.bucket_arn
    }
    sns_trigger = {
      action     = "lambda:InvokeFunction"
      principal  = "sns.amazonaws.com"
      source_arn = aws_sns_topic.lambda_notifications.arn
    }
    eventbridge_trigger = {
      action     = "lambda:InvokeFunction"
      principal  = "events.amazonaws.com"
      source_arn = aws_cloudwatch_event_rule.lambda_schedule.arn
    }
  }

  # Comprehensive IAM permissions
  additional_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
    "arn:aws:iam::aws:policy/AmazonSNSFullAccess",
    "arn:aws:iam::aws:policy/AmazonSQSFullAccess",
    "arn:aws:iam::aws:policy/AmazonRDSReadOnlyAccess",
    "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess",
    "arn:aws:iam::aws:policy/CloudWatchFullAccess",
    "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
  ]


  # Function URL with CORS
  create_function_url = var.enable_function_url
  function_url_config = {
    authorization_type = "AWS_IAM"
    cors = {
      allow_credentials = false
      allow_headers     = ["date", "keep-alive", "content-type", "authorization"]
      allow_methods     = ["GET", "POST", "PUT", "DELETE"]
      allow_origins     = ["*"]
      expose_headers    = ["date", "keep-alive"]
      max_age           = 86400
    }
  }

  lambda_insights_enabled = true
  create_log_group        = true
  log_retention_in_days   = var.log_retention_days


  tags = module.tags.tags

  depends_on = [
    module.rds
  ]
}

# =============================================================================
# EVENT SOURCE MAPPINGS AND NOTIFICATIONS
# =============================================================================

# S3 bucket notification
resource "aws_s3_bucket_notification" "lambda_notification" {
  bucket = module.s3.bucket_id

  lambda_function {
    lambda_function_arn = module.complete_lambda.lambda_function_arn
    events              = ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]
    filter_prefix       = "uploads/"
    filter_suffix       = ".json"
  }

  depends_on = [module.complete_lambda]
}

# SNS topic subscription
resource "aws_sns_topic_subscription" "lambda_subscription" {
  topic_arn = aws_sns_topic.lambda_notifications.arn
  protocol  = "lambda"
  endpoint  = module.complete_lambda.lambda_function_arn

  depends_on = [module.complete_lambda]
}

# SQS event source mapping
resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = aws_sqs_queue.lambda_queue.arn
  function_name    = module.complete_lambda.lambda_function_name
  batch_size       = 10
  enabled          = true

  depends_on = [module.complete_lambda]
}

# =============================================================================
# MONITORING AND ALARMS
# =============================================================================

# CloudWatch alarms for comprehensive monitoring
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "${var.function_name}-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "This metric monitors lambda errors"
  alarm_actions       = [aws_sns_topic.lambda_notifications.arn]

  dimensions = {
    FunctionName = module.complete_lambda.lambda_function_name
  }

  tags = {
    Environment = var.environment
    Project     = "lambda-terraform-module"
  }
}

resource "aws_cloudwatch_metric_alarm" "lambda_duration" {
  alarm_name          = "${var.function_name}-duration"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Average"
  threshold           = tostring(var.timeout * 1000 * 0.8) # 80% of timeout
  alarm_description   = "This metric monitors lambda duration"
  alarm_actions       = [aws_sns_topic.lambda_notifications.arn]

  dimensions = {
    FunctionName = module.complete_lambda.lambda_function_name
  }

  tags = {
    Environment = var.environment
    Project     = "lambda-terraform-module"
  }
}

resource "aws_cloudwatch_metric_alarm" "dlq_messages" {
  alarm_name          = "${var.function_name}-dlq-messages"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "ApproximateNumberOfVisibleMessages"
  namespace           = "AWS/SQS"
  period              = "300"
  statistic           = "Average"
  threshold           = "0"
  alarm_description   = "This metric monitors DLQ message count"
  alarm_actions       = [aws_sns_topic.lambda_notifications.arn]

  dimensions = {
    QueueName = module.complete_lambda.lambda_dead_letter_queue_name
  }

  tags = {
    Environment = var.environment
    Project     = "lambda-terraform-module"
  }

  depends_on = [module.complete_lambda]
}

# CloudWatch dashboard
resource "aws_cloudwatch_dashboard" "complete_lambda_dashboard" {
  dashboard_name = "${var.function_name}-complete-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/Lambda", "Invocations", "FunctionName", var.function_name],
            [".", "Errors", ".", "."],
            [".", "Duration", ".", "."],
            [".", "Throttles", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Lambda Function Metrics"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/Lambda", "ProvisionedConcurrencyUtilization", "FunctionName", var.function_name, "Resource", "${var.function_name}:${var.alias_name}"],
            [".", "ProvisionedConcurrencySpilloverInvocations", ".", ".", ".", "."],
            [".", "ProvisionedConcurrencyInvocations", ".", ".", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Provisioned Concurrency Metrics"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 6
        height = 6

        properties = {
          metrics = [
            ["AWS/SQS", "ApproximateNumberOfVisibleMessages", "QueueName", module.complete_lambda.lambda_dead_letter_queue_name]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Dead Letter Queue Messages"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 6
        y      = 12
        width  = 6
        height = 6

        properties = {
          metrics = [
            ["AWS/ApiGateway", "Count", "ApiName", "${var.function_name}-api"],
            [".", "Latency", ".", "."],
            [".", "4XXError", ".", "."],
            [".", "5XXError", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "API Gateway Metrics"
          period  = 300
        }
      }
    ]
  })
}
