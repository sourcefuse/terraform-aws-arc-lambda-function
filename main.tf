# =============================================================================
# DATA SOURCES
# =============================================================================
data "aws_region" "current" {}


# =============================================================================
# IAM ROLE FOR LAMBDA FUNCTION
# =============================================================================

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "default" {
  count              = var.role_arn == null ? 1 : 0
  name               = "${var.function_name}-execution-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

# Attach AWS basic execution policy if creating default role
resource "aws_iam_role_policy_attachment" "basic_execution" {
  count      = var.role_arn == null ? 1 : 0
  role       = aws_iam_role.default[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
# Attach additional user-provided policies to default role
resource "aws_iam_role_policy_attachment" "additional" {
  count      = var.role_arn == null ? length(var.additional_policy_arns) : 0
  role       = aws_iam_role.default[0].name
  policy_arn = var.additional_policy_arns[count.index]
}

# Add inline policies (provided as JSON documents)
resource "aws_iam_role_policy" "additional_policy_docs" {
  count  = var.role_arn == null ? length(var.additional_policy_docs) : 0
  name   = "${var.function_name}-inline-${count.index}"
  role   = aws_iam_role.default[0].id
  policy = var.additional_policy_docs[count.index]
}
# =============================================================================
# CLOUDWATCH LOG GROUP
# =============================================================================

resource "aws_cloudwatch_log_group" "lambda" {
  count = var.create_log_group ? 1 : 0

  name              = local.log_group_name
  retention_in_days = var.log_retention_in_days
  kms_key_id        = var.log_group_kms_key_id

  tags = var.tags

}

# =============================================================================
# DEAD LETTER QUEUE (SQS)
# =============================================================================

resource "aws_sqs_queue" "dlq" {
  count = var.create_dlq ? 1 : 0

  name                      = local.dlq_name
  message_retention_seconds = var.dlq_message_retention_seconds

  tags = var.tags
}

# =============================================================================
# LAMBDA FUNCTION
# =============================================================================

resource "aws_lambda_function" "this" {
  function_name = local.function_name
  description   = var.description
  role          = var.role_arn != null ? var.role_arn : aws_iam_role.default[0].arn
  handler       = local.handler
  runtime       = local.runtime

  memory_size = var.memory_size
  timeout     = var.timeout

  reserved_concurrent_executions = var.reserved_concurrent_executions != -1 ? var.reserved_concurrent_executions : null

  publish      = var.publish
  package_type = var.package_type

  architectures           = var.architectures
  code_signing_config_arn = var.code_signing_config_arn
  ephemeral_storage {
    size = var.ephemeral_storage
  }

  # File system configuration (optional)
  dynamic "file_system_config" {
    for_each = var.file_system_config != null ? [var.file_system_config] : []
    content {
      arn              = file_system_config.value.arn
      local_mount_path = file_system_config.value.local_mount_path
    }
  }

  kms_key_arn      = var.kms_key_arn
  source_code_hash = var.source_code_hash
  dynamic "image_config" {
    for_each = var.package_type == "Image" && var.image_config != null ? [var.image_config] : []
    content {
      command           = image_config.value.command
      entry_point       = image_config.value.entry_point
      working_directory = image_config.value.working_directory
    }
  }

  # Logging configuration (optional)
  dynamic "logging_config" {
    for_each = var.logging_config != null ? [var.logging_config] : []
    content {
      log_format = logging_config.value.log_format
      log_group  = logging_config.value.log_group
    }
  }

  replace_security_groups_on_destroy = var.replace_security_groups_on_destroy
  replacement_security_group_ids     = var.replacement_security_group_ids

  # Snap start configuration (optional)
  dynamic "snap_start" {
    for_each = var.snap_start != null ? [var.snap_start] : []
    content {
      apply_on = snap_start.value.apply_on
    }
  }

  # Tracing configuration (optional)
  dynamic "tracing_config" {
    for_each = var.tracing_config != null ? [var.tracing_config] : []
    content {
      mode = tracing_config.value.mode
    }
  }

  # Deployment package configuration
  filename          = local.has_filename ? var.filename : null
  s3_bucket         = local.has_s3_package ? var.s3_bucket : null
  s3_key            = local.has_s3_package ? var.s3_key : null
  s3_object_version = local.has_s3_package ? var.s3_object_version : null
  image_uri         = local.has_image_uri ? var.image_uri : null

  # Environment variables
  dynamic "environment" {
    for_each = local.environment_config != null ? [local.environment_config] : []
    content {
      variables = environment.value.variables
    }
  }

  # VPC configuration
  dynamic "vpc_config" {
    for_each = local.vpc_config_enabled ? [var.vpc_config] : []
    content {
      subnet_ids         = vpc_config.value.subnet_ids
      security_group_ids = vpc_config.value.security_group_ids
    }
  }

  # Dead letter configuration
  dynamic "dead_letter_config" {
    for_each = local.dlq_enabled ? [{ target_arn = local.dlq_target_arn }] : []
    content {
      target_arn = dead_letter_config.value.target_arn
    }
  }

  # Lambda Insights layer
  layers = local.lambda_insights_layer

  tags = var.tags

  depends_on = [
    aws_cloudwatch_log_group.lambda,
  ]
}

# =============================================================================
# LAMBDA ALIAS
# =============================================================================

resource "aws_lambda_alias" "this" {
  count = var.create_alias ? 1 : 0

  name             = var.alias_name
  description      = var.alias_description
  function_name    = aws_lambda_function.this.function_name
  function_version = var.alias_function_version != null ? var.alias_function_version : aws_lambda_function.this.version

  dynamic "routing_config" {
    for_each = var.alias_routing_config != null ? [var.alias_routing_config] : []

    content {
      additional_version_weights = routing_config.value.additional_version_weights
    }
  }

  depends_on = [aws_lambda_function.this]
}

# =============================================================================
# PROVISIONED CONCURRENCY
# =============================================================================

resource "aws_lambda_provisioned_concurrency_config" "this" {
  count = var.provisioned_concurrency_config != null ? 1 : 0

  function_name                     = aws_lambda_function.this.function_name
  provisioned_concurrent_executions = var.provisioned_concurrency_config.provisioned_concurrent_executions
  qualifier                         = local.provisioned_concurrency_qualifier

  depends_on = [aws_lambda_function.this, aws_lambda_alias.this]
}

# =============================================================================
# LAMBDA PERMISSIONS
# =============================================================================

resource "aws_lambda_permission" "this" {
  for_each = var.lambda_permissions

  statement_id           = each.value.statement_id != null ? each.value.statement_id : each.key
  action                 = each.value.action
  function_name          = aws_lambda_function.this.function_name
  principal              = each.value.principal
  source_arn             = each.value.source_arn
  source_account         = each.value.source_account
  qualifier              = each.value.qualifier
  function_url_auth_type = each.value.function_url_auth_type
  principal_org_id       = each.value.principal_org_id

  depends_on = [aws_lambda_function.this]
}

# =============================================================================
# LAMBDA FUNCTION URL
# =============================================================================

resource "aws_lambda_function_url" "this" {
  count = var.create_function_url ? 1 : 0

  function_name      = aws_lambda_function.this.function_name
  authorization_type = var.function_url_config.authorization_type
  invoke_mode        = var.function_url_config.invoke_mode

  dynamic "cors" {
    for_each = var.function_url_config.cors != null ? [var.function_url_config.cors] : []

    content {
      allow_credentials = cors.value.allow_credentials
      allow_headers     = cors.value.allow_headers
      allow_methods     = cors.value.allow_methods
      allow_origins     = cors.value.allow_origins
      expose_headers    = cors.value.expose_headers
      max_age           = cors.value.max_age
    }
  }

  depends_on = [aws_lambda_function.this]
}
