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

# Create a simple Python Lambda function
data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "lambda_function.zip"
  source {
    content = templatefile("${path.module}/lambda_function.py", {
      message = var.lambda_message
    })
    filename = "lambda_function.py"
  }
}

module "basic_lambda" {
  source = "../../"

  # Basic configuration
  function_name = var.function_name
  description   = "Basic Lambda function example"
  runtime       = "python3.11"
  handler       = "lambda_function.lambda_handler"
  memory_size   = 128
  timeout       = 10

  # Deployment package
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  # Environment variables
  environment_variables = {
    ENVIRONMENT = var.environment
    LOG_LEVEL   = var.log_level
  }

  # CloudWatch Logs
  create_log_group      = true
  log_retention_in_days = 7

  # Tags
  tags = {
    Environment = var.environment
    Project     = "lambda-terraform-module"
    Example     = "basic-lambda"
    ManagedBy   = "terraform"
  }
}
