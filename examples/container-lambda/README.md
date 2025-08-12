# Container Lambda Function Example

This example demonstrates how to deploy an AWS Lambda function using container images with the Lambda Terraform module. The function showcases advanced features like external API calls, parameter store integration, and structured logging.

## What This Example Creates

- ECR repository for container images with lifecycle policies
- Docker image built from local Dockerfile
- AWS Lambda function using container image deployment
- IAM role with ECR and SSM permissions
- CloudWatch log group with 30-day retention

## Prerequisites

- Docker installed and running
- AWS CLI configured
- Terraform >= 1.3.0

## Usage

1. **Ensure Docker is running:**
   ```bash
   docker --version
   ```

2. **Initialize Terraform:**
   ```bash
   terraform init
   ```

3. **Review the plan:**
   ```bash
   terraform plan
   ```

4. **Apply the configuration:**
   ```bash
   terraform apply
   ```

   Note: The first apply may take several minutes as it builds and pushes the Docker image.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0 |
| <a name="requirement_docker"></a> [docker](#requirement\_docker) | >= 3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.7.0 |
| <a name="provider_docker"></a> [docker](#provider\_docker) | 3.6.2 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_container_lambda"></a> [container\_lambda](#module\_container\_lambda) | ../../ | n/a |
| <a name="module_tags"></a> [tags](#module\_tags) | sourcefuse/arc-tags/aws | 1.2.6 |

## Resources

| Name | Type |
|------|------|
| [aws_ecr_lifecycle_policy.lambda_container](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_lifecycle_policy) | resource |
| [aws_ecr_repository.lambda_container](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository) | resource |
| [docker_image.lambda_container](https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs/resources/image) | resource |
| [docker_registry_image.lambda_container](https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs/resources/registry_image) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_ecr_authorization_token.token](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ecr_authorization_token) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region for resources | `string` | `"us-east-1"` | no |
| <a name="input_ecr_repository_name"></a> [ecr\_repository\_name](#input\_ecr\_repository\_name) | Name of the ECR repository | `string` | `"lambda-container-example"` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name | `string` | `"dev"` | no |
| <a name="input_function_name"></a> [function\_name](#input\_function\_name) | Name of the Lambda function | `string` | `"container-lambda-example"` | no |
| <a name="input_image_tag"></a> [image\_tag](#input\_image\_tag) | Tag for the container image | `string` | `"latest"` | no |
| <a name="input_log_level"></a> [log\_level](#input\_log\_level) | Log level for the Lambda function | `string` | `"INFO"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_container_image_uri"></a> [container\_image\_uri](#output\_container\_image\_uri) | URI of the container image used by Lambda |
| <a name="output_docker_image_id"></a> [docker\_image\_id](#output\_docker\_image\_id) | ID of the Docker image |
| <a name="output_ecr_repository_arn"></a> [ecr\_repository\_arn](#output\_ecr\_repository\_arn) | ARN of the ECR repository |
| <a name="output_ecr_repository_url"></a> [ecr\_repository\_url](#output\_ecr\_repository\_url) | URL of the ECR repository |
| <a name="output_lambda_function_arn"></a> [lambda\_function\_arn](#output\_lambda\_function\_arn) | ARN of the Lambda function |
| <a name="output_lambda_function_name"></a> [lambda\_function\_name](#output\_lambda\_function\_name) | Name of the Lambda function |
| <a name="output_lambda_function_version"></a> [lambda\_function\_version](#output\_lambda\_function\_version) | Version of the Lambda function |
| <a name="output_lambda_role_arn"></a> [lambda\_role\_arn](#output\_lambda\_role\_arn) | ARN of the Lambda execution role |
<!-- END_TF_DOCS -->
