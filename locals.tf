locals {
  # Function naming
  function_name  = var.function_name
  role_name      = var.role_name != null ? var.role_name : "${var.function_name}-role"
  dlq_name       = var.dlq_name != null ? var.dlq_name : "${var.function_name}-dlq"
  log_group_name = var.log_group_name != null ? var.log_group_name : "/aws/lambda/${var.function_name}"

  # Deployment package validation
  has_filename   = var.filename != null
  has_s3_package = var.s3_bucket != null && var.s3_key != null
  has_image_uri  = var.image_uri != null

  # Validate that exactly one deployment method is specified
  deployment_methods_count = (
    (local.has_filename ? 1 : 0) +
    (local.has_s3_package ? 1 : 0) +
    (local.has_image_uri ? 1 : 0)
  )

  # Package type specific configurations
  is_zip_package   = var.package_type == "Zip"
  is_image_package = var.package_type == "Image"

  # Handler is only required for Zip packages
  handler = local.is_zip_package ? var.handler : null

  # Runtime is only required for Zip packages (not for container images)
  runtime = local.is_zip_package ? var.runtime : null

  # VPC configuration
  vpc_config_enabled = var.vpc_config != null

  # Dead Letter Queue configuration
  dlq_enabled = var.create_dlq || var.dead_letter_config != null
  dlq_target_arn = var.create_dlq ? aws_sqs_queue.dlq[0].arn : (
    var.dead_letter_config != null ? var.dead_letter_config.target_arn : null
  )

  # IAM role configuration
  use_existing_role = var.role != null
  create_new_role   = var.create_role && !local.use_existing_role
  lambda_role_arn   = local.use_existing_role ? var.role : aws_iam_role.lambda[0].arn

  # Lambda Insights layer ARN mapping
  lambda_insights_layer_arns = {
    "us-east-1"      = "arn:aws:lambda:us-east-1:580247275435:layer:LambdaInsightsExtension:${var.lambda_insights_version}"
    "us-east-2"      = "arn:aws:lambda:us-east-2:580247275435:layer:LambdaInsightsExtension:${var.lambda_insights_version}"
    "us-west-1"      = "arn:aws:lambda:us-west-1:580247275435:layer:LambdaInsightsExtension:${var.lambda_insights_version}"
    "us-west-2"      = "arn:aws:lambda:us-west-2:580247275435:layer:LambdaInsightsExtension:${var.lambda_insights_version}"
    "eu-west-1"      = "arn:aws:lambda:eu-west-1:580247275435:layer:LambdaInsightsExtension:${var.lambda_insights_version}"
    "eu-west-2"      = "arn:aws:lambda:eu-west-2:580247275435:layer:LambdaInsightsExtension:${var.lambda_insights_version}"
    "eu-west-3"      = "arn:aws:lambda:eu-west-3:580247275435:layer:LambdaInsightsExtension:${var.lambda_insights_version}"
    "eu-central-1"   = "arn:aws:lambda:eu-central-1:580247275435:layer:LambdaInsightsExtension:${var.lambda_insights_version}"
    "eu-north-1"     = "arn:aws:lambda:eu-north-1:580247275435:layer:LambdaInsightsExtension:${var.lambda_insights_version}"
    "ap-northeast-1" = "arn:aws:lambda:ap-northeast-1:580247275435:layer:LambdaInsightsExtension:${var.lambda_insights_version}"
    "ap-northeast-2" = "arn:aws:lambda:ap-northeast-2:580247275435:layer:LambdaInsightsExtension:${var.lambda_insights_version}"
    "ap-southeast-1" = "arn:aws:lambda:ap-southeast-1:580247275435:layer:LambdaInsightsExtension:${var.lambda_insights_version}"
    "ap-southeast-2" = "arn:aws:lambda:ap-southeast-2:580247275435:layer:LambdaInsightsExtension:${var.lambda_insights_version}"
    "ap-south-1"     = "arn:aws:lambda:ap-south-1:580247275435:layer:LambdaInsightsExtension:${var.lambda_insights_version}"
    "ca-central-1"   = "arn:aws:lambda:ca-central-1:580247275435:layer:LambdaInsightsExtension:${var.lambda_insights_version}"
    "sa-east-1"      = "arn:aws:lambda:sa-east-1:580247275435:layer:LambdaInsightsExtension:${var.lambda_insights_version}"
  }

  # Lambda Insights layer
  lambda_insights_layer = var.lambda_insights_enabled ? [
    lookup(local.lambda_insights_layer_arns, data.aws_region.current.id, null)
  ] : []

  # Environment variables configuration
  environment_config = length(var.environment_variables) > 0 ? {
    variables = var.environment_variables
  } : null

  # Provisioned concurrency qualifier
  provisioned_concurrency_qualifier = (
    var.provisioned_concurrency_config != null ?
    (
      var.provisioned_concurrency_config.qualifier != null ?
      var.provisioned_concurrency_config.qualifier :
      (var.create_alias ? aws_lambda_alias.this[0].name : aws_lambda_function.this.version)
    )
    : null
  )

  # Merged tags
  common_tags = merge(
    var.tags,
    {
      Name      = local.function_name
      ManagedBy = "Terraform"
      Component = "Lambda"
    }
  )

  function_tags = merge(
    local.common_tags,
    var.function_tags
  )

  # Policy statements for the Lambda execution role
  base_policy_statements = {
    logs = {
      effect = "Allow"
      actions = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
      resources = [
        "arn:aws:logs:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:log-group:${local.log_group_name}",
        "arn:aws:logs:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:log-group:${local.log_group_name}:*"
      ]
    }
  }

  vpc_policy_statements = local.vpc_config_enabled ? {
    vpc = {
      effect = "Allow"
      actions = [
        "ec2:CreateNetworkInterface",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DeleteNetworkInterface",
        "ec2:AttachNetworkInterface",
        "ec2:DetachNetworkInterface"
      ]
      resources = ["*"]
    }
  } : {}

  dlq_policy_statements = local.dlq_enabled && var.create_dlq ? {
    dlq = {
      effect = "Allow"
      actions = [
        "sqs:SendMessage"
      ]
      resources = [aws_sqs_queue.dlq[0].arn]
    }
  } : {}

  lambda_insights_policy_statements = var.lambda_insights_enabled ? {
    lambda_insights = {
      effect = "Allow"
      actions = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
      resources = [
        "arn:aws:logs:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda-insights:*"
      ]
    }
  } : {}

  # Combine all policy statements
  all_policy_statements = merge(
    local.base_policy_statements,
    local.vpc_policy_statements,
    local.dlq_policy_statements,
    local.lambda_insights_policy_statements,
    var.attach_policy_statements ? var.policy_statements : {}
  )
}
