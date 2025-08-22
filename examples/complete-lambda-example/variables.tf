variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}
variable "namespace" {
  type        = string
  description = "Namespace of the project, i.e. arc"
}

variable "vpc_name" {
  type        = string
  description = "Name of the VPC to add the resources"
  default     = "arc-poc-vpc"
}
variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
  default     = "complete-lambda-example"
}

variable "function_version" {
  description = "Version identifier for the function"
  type        = string
  default     = "1.0.0"
}

variable "acl" {
  type        = string
  description = "ACL value"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "log_level" {
  description = "Log level for the Lambda function"
  type        = string
  default     = "INFO"

  validation {
    condition     = contains(["DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"], var.log_level)
    error_message = "Log level must be one of: DEBUG, INFO, WARNING, ERROR, CRITICAL."
  }
}

# Lambda Configuration
variable "memory_size" {
  description = "Amount of memory in MB your Lambda Function can use at runtime"
  type        = number
  default     = 1024

  validation {
    condition     = var.memory_size >= 128 && var.memory_size <= 10240
    error_message = "Memory size must be between 128 MB and 10,240 MB."
  }
}

variable "timeout" {
  description = "Amount of time your Lambda Function has to run in seconds"
  type        = number
  default     = 60

  validation {
    condition     = var.timeout >= 1 && var.timeout <= 900
    error_message = "Timeout must be between 1 and 900 seconds."
  }
}


# S3 Configuration
variable "s3_bucket_name" {
  description = "Name of the S3 bucket for event source"
  type        = string
  default     = "complete-lambda-example-bucket"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.s3_bucket_name))
    error_message = "S3 bucket name must be lowercase, start and end with alphanumeric characters, and can contain hyphens."
  }
}

# Dead Letter Queue Configuration
variable "dlq_retention_seconds" {
  description = "Number of seconds to retain messages in the DLQ"
  type        = number
  default     = 1209600 # 14 days

  validation {
    condition     = var.dlq_retention_seconds >= 60 && var.dlq_retention_seconds <= 1209600
    error_message = "DLQ retention must be between 60 seconds and 1,209,600 seconds (14 days)."
  }
}

# Alias Configuration
variable "alias_name" {
  description = "Name of the Lambda alias"
  type        = string
  default     = "production"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]+$", var.alias_name))
    error_message = "Alias name must contain only alphanumeric characters, hyphens, and underscores."
  }
}

# API Gateway Configuration
variable "api_stage_name" {
  description = "API Gateway stage name"
  type        = string
  default     = "prod"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]+$", var.api_stage_name))
    error_message = "API stage name must contain only alphanumeric characters, hyphens, and underscores."
  }
}

# EventBridge Configuration
variable "schedule_expression" {
  description = "EventBridge schedule expression for periodic invocation"
  type        = string
  default     = "rate(10 minutes)"

  validation {
    condition     = can(regex("^(rate\\(.*\\)|cron\\(.*\\))$", var.schedule_expression))
    error_message = "Schedule expression must be a valid EventBridge schedule expression (rate() or cron())."
  }
}

# Function URL Configuration
variable "enable_function_url" {
  description = "Whether to create a Lambda function URL"
  type        = bool
  default     = true
}

# CloudWatch Configuration
variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 30

  validation {
    condition = contains([
      1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653
    ], var.log_retention_days)
    error_message = "Log retention must be a valid CloudWatch Logs retention value."
  }
}

# Notification Configuration
variable "notification_email" {
  description = "Email address for notifications (leave empty to disable)"
  type        = string
  default     = ""

  validation {
    condition     = var.notification_email == "" || can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.notification_email))
    error_message = "Must be a valid email address or empty string."
  }
}

# SSM Parameters Configuration
variable "ssm_parameters" {
  description = "SSM parameters to create for the Lambda function"
  type = map(object({
    type  = string
    value = string
  }))
  default = {
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
    "secrets/api_key" = {
      type  = "SecureString"
      value = "complete-example-api-key-12345"
    }
    "secrets/db_connection_string" = {
      type  = "SecureString"
      value = "postgresql://dbadmin:password@localhost:5432/lambdadb"
    }
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
  }

  validation {
    condition = alltrue([
      for param in values(var.ssm_parameters) : contains(["String", "StringList", "SecureString"], param.type)
    ])
    error_message = "SSM parameter type must be one of: String, StringList, SecureString."
  }
}
