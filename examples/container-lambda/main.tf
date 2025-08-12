terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = ">= 3.0"
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

# Get current AWS account ID and region
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Create ECR repository for Lambda container images
resource "aws_ecr_repository" "lambda_container" {
  name                 = var.ecr_repository_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Environment = var.environment
    Project     = "lambda-terraform-module"
    Purpose     = "lambda-container-images"
  }
}

resource "aws_ecr_lifecycle_policy" "lambda_container" {
  repository = aws_ecr_repository.lambda_container.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v"]
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Delete untagged images older than 1 day"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 1
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# Configure Docker provider to authenticate with ECR
data "aws_ecr_authorization_token" "token" {}

provider "docker" {
  registry_auth {
    address  = data.aws_ecr_authorization_token.token.proxy_endpoint
    username = data.aws_ecr_authorization_token.token.user_name
    password = data.aws_ecr_authorization_token.token.password
  }
}

# Build and push Docker image
resource "docker_image" "lambda_container" {
  name = "${aws_ecr_repository.lambda_container.repository_url}:${var.image_tag}"

  build {
    context    = path.module
    dockerfile = "Dockerfile"
    build_args = {
      FUNCTION_NAME = var.function_name
      ENVIRONMENT   = var.environment
    }
  }

  triggers = {
    dockerfile_hash   = filemd5("${path.module}/Dockerfile")
    app_hash          = filemd5("${path.module}/app.py")
    requirements_hash = filemd5("${path.module}/requirements.txt")
  }
}

resource "docker_registry_image" "lambda_container" {
  name = docker_image.lambda_container.name

  triggers = {
    dockerfile_hash   = filemd5("${path.module}/Dockerfile")
    app_hash          = filemd5("${path.module}/app.py")
    requirements_hash = filemd5("${path.module}/requirements.txt")
  }
}

# Create Lambda function from container image
module "container_lambda" {
  source = "../../"

  # Basic configuration
  function_name = var.function_name
  description   = "Lambda function using container image"
  package_type  = "Image"
  memory_size   = 512
  timeout       = 60
  architectures = ["x86_64"]

  # Container image configuration
  image_uri = "${aws_ecr_repository.lambda_container.repository_url}:${var.image_tag}"

  # Environment variables
  environment_variables = {
    ENVIRONMENT = var.environment
    LOG_LEVEL   = var.log_level
    APP_VERSION = var.image_tag
  }
  # IAM permissions for additional AWS services
  create_role              = true
  attach_policy_statements = true
  policy_statements = {
    ecr_access = {
      effect = "Allow"
      actions = [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage"
      ]
      resources = ["*"]
    }
    ssm_access = {
      effect = "Allow"
      actions = [
        "ssm:GetParameter",
        "ssm:GetParameters"
      ]
      resources = [
        "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/${var.function_name}/*"
      ]
    }
  }

  # CloudWatch Logs
  create_log_group      = true
  log_retention_in_days = 30

  # Versioning
  publish = true

  tags = module.tags.tags

  depends_on = [docker_registry_image.lambda_container]
}
