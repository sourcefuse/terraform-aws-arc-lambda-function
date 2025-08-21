# =============================================================================
# REQUIRED VARIABLES
# =============================================================================

variable "function_name" {
  description = "Name of the Lambda function"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]+$", var.function_name))
    error_message = "Function name must contain only alphanumeric characters, hyphens, and underscores."
  }
}

variable "runtime" {
  description = "Runtime for the Lambda function (e.g., python3.9, nodejs18.x, java11, etc.)"
  type        = string
  default     = "python3.9"

  validation {
    condition = contains([
      "nodejs18.x", "nodejs20.x",
      "python3.8", "python3.9", "python3.10", "python3.11", "python3.12",
      "java8.al2", "java11", "java17", "java21",
      "dotnet6", "dotnet8",
      "go1.x",
      "ruby3.2", "ruby3.3",
      "provided.al2", "provided.al2023"
    ], var.runtime)
    error_message = "Runtime must be a valid AWS Lambda runtime."
  }
}

# =============================================================================
# DEPLOYMENT PACKAGE CONFIGURATION
# =============================================================================

variable "package_type" {
  description = "Lambda deployment package type (Zip or Image)"
  type        = string
  default     = "Zip"

  validation {
    condition     = contains(["Zip", "Image"], var.package_type)
    error_message = "Package type must be either 'Zip' or 'Image'."
  }
}

variable "filename" {
  description = "Path to the function's deployment package within the local filesystem"
  type        = string
  default     = null
}

variable "s3_bucket" {
  description = "S3 bucket location containing the function's deployment package"
  type        = string
  default     = null
}

variable "s3_key" {
  description = "S3 key of an object containing the function's deployment package"
  type        = string
  default     = null
}

variable "s3_object_version" {
  description = "Object version containing the function's deployment package"
  type        = string
  default     = null
}

variable "image_uri" {
  description = "ECR image URI containing the function's deployment package"
  type        = string
  default     = null
}

variable "source_code_hash" {
  description = "Used to trigger updates. Must be set to a base64-encoded SHA256 hash of the package file specified with either filename or s3_key"
  type        = string
  default     = null
}

# =============================================================================
# FUNCTION CONFIGURATION
# =============================================================================

variable "handler" {
  description = "Function entrypoint in your code"
  type        = string
  default     = "index.handler"
}

variable "description" {
  description = "Description of what your Lambda Function does"
  type        = string
  default     = "Lambda function created by Terraform"
}

variable "memory_size" {
  description = "Amount of memory in MB your Lambda Function can use at runtime"
  type        = number
  default     = 128

  validation {
    condition     = var.memory_size >= 128 && var.memory_size <= 10240
    error_message = "Memory size must be between 128 MB and 10,240 MB."
  }
}

variable "image_config" {
  description = "Configuration for Lambda when using container images"
  type = object({
    command           = list(string)
    entry_point       = list(string)
    working_directory = string
  })
  default = null
}

# Optional: Logging configuration for Lambda
variable "logging_config" {
  description = "Logging configuration for Lambda function"
  type = object({
    log_format = string # e.g., "JSON" or "Text"
    log_group  = string # e.g., "/aws/lambda/my-function"
  })
  default = null
}

variable "replace_security_groups_on_destroy" {
  description = "Whether to force replacement of security groups on destroy"
  type        = bool
  default     = false
}

variable "replacement_security_group_ids" {
  description = "List of replacement security group IDs to use"
  type        = list(string)
  default     = []
}

variable "snap_start" {
  description = "SnapStart configuration for Lambda function"
  type = object({
    apply_on = string # e.g., "PublishedVersions"
  })
  default = null
}

variable "tracing_config" {
  description = "Tracing configuration for Lambda function"
  type = object({
    mode = string # e.g., "Active" or "PassThrough"
  })
  default = null
}

variable "timeout" {
  description = "Amount of time your Lambda Function has to run in seconds"
  type        = number
  default     = 3

  validation {
    condition     = var.timeout >= 1 && var.timeout <= 900
    error_message = "Timeout must be between 1 and 900 seconds."
  }
}
variable "code_signing_config_arn" {
  description = "ARN of code signing config"
  type        = string
  default     = null
}

variable "ephemeral_storage" {
  description = "Ephemeral storage size in MB (512-10240)"
  type        = number
  default     = 512
}

variable "file_system_config" {
  description = "File system configuration for the Lambda function"
  type = object({
    arn              = string
    local_mount_path = string
  })
  default = null
}
variable "reserved_concurrent_executions" {
  description = "Amount of reserved concurrent executions for this lambda function"
  type        = number
  default     = -1
}

variable "architectures" {
  description = "Instruction set architecture for your Lambda function"
  type        = list(string)
  default     = ["x86_64"]

  validation {
    condition = alltrue([
      for arch in var.architectures : contains(["x86_64", "arm64"], arch)
    ])
    error_message = "Architectures must be either 'x86_64' or 'arm64'."
  }
}

# =============================================================================
# ENVIRONMENT VARIABLES
# =============================================================================

variable "environment_variables" {
  description = "Map of environment variables that are accessible from the function code during execution"
  type        = map(string)
  default     = {}
}

variable "kms_key_arn" {
  description = "Amazon Resource Name (ARN) of the AWS Key Management Service (KMS) key that's used to encrypt your function's environment variables"
  type        = string
  default     = null
}

# =============================================================================
# VPC CONFIGURATION
# =============================================================================

variable "vpc_config" {
  description = "VPC configuration for the Lambda function"
  type = object({
    subnet_ids         = list(string)
    security_group_ids = list(string)
  })
  default = null
}

# =============================================================================
# DEAD LETTER QUEUE CONFIGURATION
# =============================================================================

variable "dead_letter_config" {
  description = "Dead letter queue configuration"
  type = object({
    target_arn = string
  })
  default = null
}

variable "create_dlq" {
  description = "Whether to create a dead letter queue (SQS) for the Lambda function"
  type        = bool
  default     = false
}

variable "dlq_name" {
  description = "Name of the dead letter queue (if create_dlq is true)"
  type        = string
  default     = null
}

variable "dlq_message_retention_seconds" {
  description = "The number of seconds Amazon SQS retains a message in the DLQ"
  type        = number
  default     = 1209600 # 14 days

  validation {
    condition     = var.dlq_message_retention_seconds >= 60 && var.dlq_message_retention_seconds <= 1209600
    error_message = "DLQ message retention must be between 60 seconds and 1,209,600 seconds (14 days)."
  }
}

# =============================================================================
# IAM CONFIGURATION
# =============================================================================


variable "role_arn" {
  description = "Existing IAM role ARN to use. If null, a default role will be created."
  type        = string
  default     = null
}

variable "additional_policy_arns" {
  description = "List of additional IAM policy ARNs to attach to the Lambda role"
  type        = list(string)
  default     = []
}
variable "inline_policies" {
  type        = list(string)
  default     = []
  description = "List of inline IAM policy JSON documents"
}
# =============================================================================
# VERSIONING AND ALIASES
# =============================================================================

variable "publish" {
  description = "Whether to publish creation/change as new Lambda Function Version"
  type        = bool
  default     = false
}

variable "create_alias" {
  description = "Whether to create an alias for the Lambda function"
  type        = bool
  default     = false
}

variable "alias_name" {
  description = "Name for the alias"
  type        = string
  default     = "live"
}

variable "alias_description" {
  description = "Description of the alias"
  type        = string
  default     = "Lambda function alias"
}

variable "alias_function_version" {
  description = "Lambda function version for which you are creating the alias"
  type        = string
  default     = null
}

variable "alias_routing_config" {
  description = "The Lambda alias routing configuration"
  type = object({
    additional_version_weights = map(number)
  })
  default = null
}

# =============================================================================
# PROVISIONED CONCURRENCY
# =============================================================================

variable "provisioned_concurrency_config" {
  description = "Provisioned concurrency configuration"
  type = object({
    provisioned_concurrent_executions = number
    qualifier                         = string
  })
  default = null
}

# =============================================================================
# CLOUDWATCH LOGS
# =============================================================================

variable "create_log_group" {
  description = "Whether to create a CloudWatch log group for the Lambda function"
  type        = bool
  default     = true
}

variable "log_group_name" {
  description = "Name of the CloudWatch log group"
  type        = string
  default     = null
}

variable "log_retention_in_days" {
  description = "Specifies the number of days you want to retain log events in the specified log group"
  type        = number
  default     = 14

  validation {
    condition = contains([
      1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653
    ], var.log_retention_in_days)
    error_message = "Log retention must be a valid CloudWatch Logs retention value."
  }
}

variable "log_group_kms_key_id" {
  description = "The ARN of the KMS Key to use when encrypting log data"
  type        = string
  default     = null
}

# =============================================================================
# LAMBDA INSIGHTS
# =============================================================================

variable "lambda_insights_enabled" {
  description = "Whether to enable Lambda Insights for the function"
  type        = bool
  default     = false
}

variable "lambda_insights_version" {
  description = "Version of the Lambda Insights layer"
  type        = string
  default     = "1"
}

# =============================================================================
# LAMBDA PERMISSIONS
# =============================================================================

variable "lambda_permissions" {
  description = "Map of Lambda permissions to create"
  type = map(object({
    action                 = string
    principal              = string
    source_arn             = optional(string)
    source_account         = optional(string)
    statement_id           = optional(string)
    qualifier              = optional(string)
    function_url_auth_type = optional(string)
    principal_org_id       = optional(string)
  }))
  default = {}
}

# =============================================================================
# FUNCTION URL
# =============================================================================

variable "create_function_url" {
  description = "Whether to create a Lambda function URL"
  type        = bool
  default     = false
}

variable "function_url_config" {
  description = "Lambda function URL configuration"
  type = object({
    authorization_type = string
    cors = optional(object({
      allow_credentials = optional(bool, false)
      allow_headers     = optional(list(string), [])
      allow_methods     = optional(list(string), [])
      allow_origins     = optional(list(string), [])
      expose_headers    = optional(list(string), [])
      max_age           = optional(number, 0)
    }))
    invoke_mode = optional(string, "BUFFERED")
  })
  default = {
    authorization_type = "AWS_IAM"
  }
}

# =============================================================================
# TAGS
# =============================================================================

variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default     = {}
}
