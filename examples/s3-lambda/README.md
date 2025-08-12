# Advanced S3 Lambda Function Example

This example demonstrates a comprehensive, production-ready AWS Lambda function for advanced S3 file processing. It showcases multiple S3 integration patterns, event-driven processing, batch operations, and monitoring capabilities using the Lambda Terraform module.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_archive"></a> [archive](#requirement\_archive) | >= 2.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_archive"></a> [archive](#provider\_archive) | 2.7.1 |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.8.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_s3_advanced_lambda"></a> [s3\_advanced\_lambda](#module\_s3\_advanced\_lambda) | ../../ | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_metric_alarm.lambda_duration_alarm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.lambda_error_alarm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_lambda_permission.allow_s3_invoke](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_s3_bucket.destination_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket.lambda_deployments](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket.source_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_notification.source_bucket_notification](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_notification) | resource |
| [aws_s3_bucket_public_access_block.destination_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_public_access_block.lambda_deployments](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_public_access_block.source_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.destination_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.lambda_deployments](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.source_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.destination_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_s3_bucket_versioning.lambda_deployments](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_s3_bucket_versioning.source_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_s3_object.lambda_package](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |
| [archive_file.lambda_zip](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region for resources | `string` | `"us-east-1"` | no |
| <a name="input_deployment_bucket_name"></a> [deployment\_bucket\_name](#input\_deployment\_bucket\_name) | S3 bucket name for Lambda deployment packages (must be globally unique) | `string` | `"lambda-deployments-advanced-example"` | no |
| <a name="input_destination_bucket_name"></a> [destination\_bucket\_name](#input\_destination\_bucket\_name) | S3 bucket name for processed files (must be globally unique) | `string` | `"s3-processed-files-advanced-example"` | no |
| <a name="input_enable_lambda_insights"></a> [enable\_lambda\_insights](#input\_enable\_lambda\_insights) | Enable Lambda Insights for enhanced monitoring | `bool` | `true` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name | `string` | `"dev"` | no |
| <a name="input_file_extension_filter"></a> [file\_extension\_filter](#input\_file\_extension\_filter) | File extension filter for S3 events | `string` | `".txt"` | no |
| <a name="input_function_name"></a> [function\_name](#input\_function\_name) | Name of the Lambda function | `string` | `"s3-advanced-processor"` | no |
| <a name="input_log_level"></a> [log\_level](#input\_log\_level) | Log level for the Lambda function | `string` | `"INFO"` | no |
| <a name="input_processing_prefix"></a> [processing\_prefix](#input\_processing\_prefix) | S3 prefix for files to be processed | `string` | `"incoming/"` | no |
| <a name="input_sns_topic_arn"></a> [sns\_topic\_arn](#input\_sns\_topic\_arn) | SNS topic ARN for CloudWatch alarms (optional) | `string` | `""` | no |
| <a name="input_source_bucket_name"></a> [source\_bucket\_name](#input\_source\_bucket\_name) | S3 bucket name for source files to be processed (must be globally unique) | `string` | `"s3-source-files-advanced-example"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cloudwatch_duration_alarm_arn"></a> [cloudwatch\_duration\_alarm\_arn](#output\_cloudwatch\_duration\_alarm\_arn) | ARN of the CloudWatch duration alarm |
| <a name="output_cloudwatch_error_alarm_arn"></a> [cloudwatch\_error\_alarm\_arn](#output\_cloudwatch\_error\_alarm\_arn) | ARN of the CloudWatch error alarm |
| <a name="output_deployment_bucket_arn"></a> [deployment\_bucket\_arn](#output\_deployment\_bucket\_arn) | ARN of the S3 bucket for Lambda deployments |
| <a name="output_deployment_bucket_name"></a> [deployment\_bucket\_name](#output\_deployment\_bucket\_name) | Name of the S3 bucket for Lambda deployments |
| <a name="output_destination_bucket_arn"></a> [destination\_bucket\_arn](#output\_destination\_bucket\_arn) | ARN of the S3 destination bucket |
| <a name="output_destination_bucket_name"></a> [destination\_bucket\_name](#output\_destination\_bucket\_name) | Name of the S3 destination bucket |
| <a name="output_lambda_alias_arn"></a> [lambda\_alias\_arn](#output\_lambda\_alias\_arn) | ARN of the Lambda alias |
| <a name="output_lambda_cloudwatch_log_group_name"></a> [lambda\_cloudwatch\_log\_group\_name](#output\_lambda\_cloudwatch\_log\_group\_name) | Name of the CloudWatch log group |
| <a name="output_lambda_dead_letter_queue_arn"></a> [lambda\_dead\_letter\_queue\_arn](#output\_lambda\_dead\_letter\_queue\_arn) | ARN of the Dead Letter Queue |
| <a name="output_lambda_function_arn"></a> [lambda\_function\_arn](#output\_lambda\_function\_arn) | ARN of the Lambda function |
| <a name="output_lambda_function_invoke_arn"></a> [lambda\_function\_invoke\_arn](#output\_lambda\_function\_invoke\_arn) | Invoke ARN of the Lambda function |
| <a name="output_lambda_function_name"></a> [lambda\_function\_name](#output\_lambda\_function\_name) | Name of the Lambda function |
| <a name="output_lambda_package_s3_key"></a> [lambda\_package\_s3\_key](#output\_lambda\_package\_s3\_key) | S3 key of the Lambda deployment package |
| <a name="output_lambda_role_arn"></a> [lambda\_role\_arn](#output\_lambda\_role\_arn) | ARN of the Lambda execution role |
| <a name="output_source_bucket_arn"></a> [source\_bucket\_arn](#output\_source\_bucket\_arn) | ARN of the S3 source bucket |
| <a name="output_source_bucket_name"></a> [source\_bucket\_name](#output\_source\_bucket\_name) | Name of the S3 source bucket |
<!-- END_TF_DOCS -->
