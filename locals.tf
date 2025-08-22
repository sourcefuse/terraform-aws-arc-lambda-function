locals {
  # Function naming
  function_name  = var.function_name
  dlq_name       = var.dlq_name != null ? var.dlq_name : "${var.function_name}-dlq"
  log_group_name = var.log_group_name != null ? var.log_group_name : "/aws/lambda/${var.function_name}"

  # Deployment package validation
  has_filename   = var.filename != null
  has_s3_package = var.s3_bucket != null && var.s3_key != null
  has_image_uri  = var.image_uri != null


  # Package type specific configurations
  is_zip_package = var.package_type == "Zip"

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
}
