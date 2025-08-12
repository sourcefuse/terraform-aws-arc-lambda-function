variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
  default     = "container-lambda-example"
}

variable "ecr_repository_name" {
  description = "Name of the ECR repository"
  type        = string
  default     = "lambda-container-example"

  validation {
    condition     = can(regex("^[a-z0-9](?:[a-z0-9._-]*[a-z0-9])?$", var.ecr_repository_name))
    error_message = "ECR repository name must be lowercase and can contain letters, numbers, hyphens, underscores, and periods."
  }
}

variable "image_tag" {
  description = "Tag for the container image"
  type        = string
  default     = "latest"
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
