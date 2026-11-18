# Basic Lambda Function Example

This example demonstrates how to create a simple AWS Lambda function using the Lambda Terraform module. The function is deployed from local source code and includes basic logging and environment variable configuration.

## What This Example Creates

- AWS Lambda function with Python 3.11 runtime
- IAM role with basic Lambda execution permissions
- CloudWatch log group with 7-day retention
- Simple Python function that returns a JSON response

## Usage

1. **Initialize Terraform:**
   ```bash
   terraform init
   ```

2. **Review the plan:**
   ```bash
   terraform plan
   ```

3. **Apply the configuration:**
   ```bash
   terraform apply
   ```

4. **Test the function:**
   ```bash
   aws lambda invoke \
     --function-name basic-lambda-example \
     --payload '{"test": "data"}' \
     response.json

   cat response.json
   ```

5. **Clean up:**
   ```bash
   terraform destroy
   ```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.17.0 |
| <a name="requirement_archive"></a> [archive](#requirement\_archive) | ~> 2.7 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_archive"></a> [archive](#provider\_archive) | 2.8.1 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_basic_lambda"></a> [basic\_lambda](#module\_basic\_lambda) | ../../ | n/a |
| <a name="module_tags"></a> [tags](#module\_tags) | sourcefuse/arc-tags/aws | 1.2.9 |

## Resources

| Name | Type |
|------|------|
| [archive_file.lambda_zip](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region for resources | `string` | `"us-east-1"` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name | `string` | `"dev"` | no |
| <a name="input_function_name"></a> [function\_name](#input\_function\_name) | Name of the Lambda function | `string` | `"basic-lambda-example"` | no |
| <a name="input_lambda_message"></a> [lambda\_message](#input\_lambda\_message) | Message to be returned by the Lambda function | `string` | `"Hello from Basic Lambda!"` | no |
| <a name="input_log_level"></a> [log\_level](#input\_log\_level) | Log level for the Lambda function | `string` | `"INFO"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_arn"></a> [arn](#output\_arn) | ARN of the Lambda function |
| <a name="output_cloudwatch_log_group_name"></a> [cloudwatch\_log\_group\_name](#output\_cloudwatch\_log\_group\_name) | Name of the CloudWatch log group |
| <a name="output_invoke_arn"></a> [invoke\_arn](#output\_invoke\_arn) | Invoke ARN of the Lambda function |
| <a name="output_name"></a> [name](#output\_name) | Name of the Lambda function |
| <a name="output_role_arn"></a> [role\_arn](#output\_role\_arn) | ARN of the Lambda execution role |
<!-- END_TF_DOCS -->
