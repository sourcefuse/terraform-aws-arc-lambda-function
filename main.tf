# =============================================================================
# DATA SOURCES
# =============================================================================

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# =============================================================================
# VALIDATION CHECKS
# =============================================================================

# Validate deployment package configuration
resource "null_resource" "validate_deployment_package" {
  provisioner "local-exec" {
    command = <<EOT
      if [ "${local.deployment_methods_count}" -ne 1 ]; then
        echo 'Error: Exactly one of filename, s3_bucket+s3_key, or image_uri must be specified'
        exit 1
      fi
    EOT
  }
}

resource "null_resource" "validate_package_compatibility" {
  provisioner "local-exec" {
    command = <<EOT
      if { [ "${local.is_zip_package}" = true ] && [ "${local.has_image_uri}" = true ]; } ||
         { [ "${local.is_image_package}" = true ] && { [ "${local.has_filename}" = true ] || [ "${local.has_s3_package}" = true ]; } }; then
        echo 'Error: Package type and deployment method are incompatible'
        exit 1
      fi
    EOT
  }
}

# =============================================================================
# IAM ROLE FOR LAMBDA FUNCTION
# =============================================================================

data "aws_iam_policy_document" "lambda_assume_role" {
  count = local.create_new_role ? 1 : 0

  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "lambda" {
  count = local.create_new_role ? 1 : 0

  name                 = local.role_name
  path                 = var.role_path
  assume_role_policy   = data.aws_iam_policy_document.lambda_assume_role[0].json
  permissions_boundary = var.role_permissions_boundary

  tags = local.common_tags
}

# Create inline policy for Lambda execution role
data "aws_iam_policy_document" "lambda_execution" {
  count = local.create_new_role ? 1 : 0

  dynamic "statement" {
    for_each = local.all_policy_statements

    content {
      effect    = statement.value.effect
      actions   = statement.value.actions
      resources = statement.value.resources

      dynamic "condition" {
        for_each = try(statement.value.conditions, [])
        content {
          test     = condition.value.test
          variable = condition.value.variable
          values   = condition.value.values
        }
      }
    }
  }
}


resource "aws_iam_role_policy" "lambda_execution" {
  count = local.create_new_role ? 1 : 0

  name   = "${local.role_name}-execution-policy"
  role   = aws_iam_role.lambda[0].id
  policy = data.aws_iam_policy_document.lambda_execution[0].json
}

# =============================================================================
# CLOUDWATCH LOG GROUP
# =============================================================================

resource "aws_cloudwatch_log_group" "lambda" {
  count = var.create_log_group ? 1 : 0

  name              = local.log_group_name
  retention_in_days = var.log_retention_in_days
  kms_key_id        = var.log_group_kms_key_id

  tags = local.common_tags

  depends_on = [aws_iam_role_policy.lambda_execution]
}

# =============================================================================
# DEAD LETTER QUEUE (SQS)
# =============================================================================

resource "aws_sqs_queue" "dlq" {
  count = var.create_dlq ? 1 : 0

  name                      = local.dlq_name
  message_retention_seconds = var.dlq_message_retention_seconds

  tags = local.common_tags
}

# =============================================================================
# LAMBDA FUNCTION
# =============================================================================

resource "aws_lambda_function" "this" {
  function_name = local.function_name
  description   = var.description
  role          = local.lambda_role_arn
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

  tags = local.function_tags

  lifecycle {
    ignore_changes = [
      source_code_hash,
    ]
  }

  depends_on = [
    null_resource.validate_deployment_package,
    null_resource.validate_package_compatibility,
    aws_cloudwatch_log_group.lambda,
    aws_iam_role_policy.lambda_execution,
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
