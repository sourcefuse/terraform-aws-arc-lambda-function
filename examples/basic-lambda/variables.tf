variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
  default     = "basic-lambda-example"
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
}

variable "lambda_message" {
  description = "Message to be returned by the Lambda function"
  type        = string
  default     = "Hello from Basic Lambda!"
}
