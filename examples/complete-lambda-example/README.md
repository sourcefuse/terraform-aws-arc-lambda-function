# Complete Lambda Example - All Features Showcase

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
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.100.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_arc_security_group"></a> [arc\_security\_group](#module\_arc\_security\_group) | sourcefuse/arc-security-group/aws | 0.0.1 |
| <a name="module_complete_lambda"></a> [complete\_lambda](#module\_complete\_lambda) | ../../ | n/a |
| <a name="module_rds"></a> [rds](#module\_rds) | sourcefuse/arc-db/aws | 4.0.1 |
| <a name="module_s3"></a> [s3](#module\_s3) | sourcefuse/arc-s3/aws | 0.0.4 |
| <a name="module_tags"></a> [tags](#module\_tags) | sourcefuse/arc-tags/aws | 1.2.6 |

## Resources

| Name | Type |
|------|------|
| [aws_api_gateway_deployment.lambda_deployment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_deployment) | resource |
| [aws_api_gateway_integration.lambda_integration](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_integration) | resource |
| [aws_api_gateway_method.lambda_method](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_method) | resource |
| [aws_api_gateway_resource.lambda_resource](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_resource) | resource |
| [aws_api_gateway_rest_api.lambda_api](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_rest_api) | resource |
| [aws_api_gateway_stage.lambda_stage](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_stage) | resource |
| [aws_cloudwatch_dashboard.complete_lambda_dashboard](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_dashboard) | resource |
| [aws_cloudwatch_event_rule.lambda_schedule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_target.lambda_target](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_cloudwatch_metric_alarm.dlq_messages](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.lambda_duration](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.lambda_errors](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_kms_alias.lambda_key_alias](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.lambda_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_lambda_event_source_mapping.sqs_trigger](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_event_source_mapping) | resource |
| [aws_s3_bucket_notification.lambda_notification](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_notification) | resource |
| [aws_sns_topic.lambda_notifications](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_sns_topic_subscription.email_notification](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription) | resource |
| [aws_sns_topic_subscription.lambda_subscription](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription) | resource |
| [aws_sqs_queue.lambda_queue](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue) | resource |
| [aws_ssm_parameter.lambda_config](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [archive_file.lambda_zip](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [aws_kms_key.sns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/kms_key) | data source |
| [aws_subnets.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnets) | data source |
| [aws_vpc.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |
| [aws_vpc.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_acl"></a> [acl](#input\_acl) | ACL value | `string` | n/a | yes |
| <a name="input_alias_name"></a> [alias\_name](#input\_alias\_name) | Name of the Lambda alias | `string` | `"production"` | no |
| <a name="input_api_stage_name"></a> [api\_stage\_name](#input\_api\_stage\_name) | API Gateway stage name | `string` | `"prod"` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region for resources | `string` | `"us-east-1"` | no |
| <a name="input_dlq_retention_seconds"></a> [dlq\_retention\_seconds](#input\_dlq\_retention\_seconds) | Number of seconds to retain messages in the DLQ | `number` | `1209600` | no |
| <a name="input_enable_function_url"></a> [enable\_function\_url](#input\_enable\_function\_url) | Whether to create a Lambda function URL | `bool` | `true` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name | `string` | `"dev"` | no |
| <a name="input_function_name"></a> [function\_name](#input\_function\_name) | Name of the Lambda function | `string` | `"complete-lambda-example"` | no |
| <a name="input_function_version"></a> [function\_version](#input\_function\_version) | Version identifier for the function | `string` | `"1.0.0"` | no |
| <a name="input_log_level"></a> [log\_level](#input\_log\_level) | Log level for the Lambda function | `string` | `"INFO"` | no |
| <a name="input_log_retention_days"></a> [log\_retention\_days](#input\_log\_retention\_days) | Number of days to retain CloudWatch logs | `number` | `30` | no |
| <a name="input_memory_size"></a> [memory\_size](#input\_memory\_size) | Amount of memory in MB your Lambda Function can use at runtime | `number` | `1024` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace of the project, i.e. arc | `string` | n/a | yes |
| <a name="input_notification_email"></a> [notification\_email](#input\_notification\_email) | Email address for notifications (leave empty to disable) | `string` | `""` | no |
| <a name="input_s3_bucket_name"></a> [s3\_bucket\_name](#input\_s3\_bucket\_name) | Name of the S3 bucket for event source | `string` | `"complete-lambda-example-bucket"` | no |
| <a name="input_schedule_expression"></a> [schedule\_expression](#input\_schedule\_expression) | EventBridge schedule expression for periodic invocation | `string` | `"rate(10 minutes)"` | no |
| <a name="input_ssm_parameters"></a> [ssm\_parameters](#input\_ssm\_parameters) | SSM parameters to create for the Lambda function | <pre>map(object({<br/>    type  = string<br/>    value = string<br/>  }))</pre> | <pre>{<br/>  "config/batch_size": {<br/>    "type": "String",<br/>    "value": "10"<br/>  },<br/>  "config/debug_mode": {<br/>    "type": "String",<br/>    "value": "false"<br/>  },<br/>  "config/enable_metrics": {<br/>    "type": "String",<br/>    "value": "true"<br/>  },<br/>  "config/max_retries": {<br/>    "type": "String",<br/>    "value": "5"<br/>  },<br/>  "config/timeout_seconds": {<br/>    "type": "String",<br/>    "value": "30"<br/>  },<br/>  "features/enable_database_logging": {<br/>    "type": "String",<br/>    "value": "true"<br/>  },<br/>  "features/enable_s3_processing": {<br/>    "type": "String",<br/>    "value": "true"<br/>  },<br/>  "features/enable_sns_notifications": {<br/>    "type": "String",<br/>    "value": "true"<br/>  },<br/>  "secrets/api_key": {<br/>    "type": "SecureString",<br/>    "value": "complete-example-api-key-12345"<br/>  },<br/>  "secrets/db_connection_string": {<br/>    "type": "SecureString",<br/>    "value": "postgresql://dbadmin:password@localhost:5432/lambdadb"<br/>  }<br/>}</pre> | no |
| <a name="input_timeout"></a> [timeout](#input\_timeout) | Amount of time your Lambda Function has to run in seconds | `number` | `60` | no |
| <a name="input_vpc_name"></a> [vpc\_name](#input\_vpc\_name) | Name of the VPC to add the resources | `string` | `"arc-poc-vpc"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_alias_arn"></a> [alias\_arn](#output\_alias\_arn) | ARN of the Lambda alias |
| <a name="output_alias_name"></a> [alias\_name](#output\_alias\_name) | Name of the Lambda alias |
| <a name="output_arn"></a> [arn](#output\_arn) | ARN of the Lambda function |
| <a name="output_cloudwatch_dashboard_url"></a> [cloudwatch\_dashboard\_url](#output\_cloudwatch\_dashboard\_url) | URL to the CloudWatch dashboard |
| <a name="output_dead_letter_queue_arn"></a> [dead\_letter\_queue\_arn](#output\_dead\_letter\_queue\_arn) | ARN of the Dead Letter Queue |
| <a name="output_dead_letter_queue_url"></a> [dead\_letter\_queue\_url](#output\_dead\_letter\_queue\_url) | URL of the Dead Letter Queue |
| <a name="output_insights_url"></a> [insights\_url](#output\_insights\_url) | URL to Lambda Insights |
| <a name="output_name"></a> [name](#output\_name) | Name of the Lambda function |
| <a name="output_role_arn"></a> [role\_arn](#output\_role\_arn) | ARN of the Lambda execution role |
| <a name="output_s3_bucket_name"></a> [s3\_bucket\_name](#output\_s3\_bucket\_name) | Name of the S3 bucket for event source |
| <a name="output_url"></a> [url](#output\_url) | Lambda function URL (if enabled) |
| <a name="output_version"></a> [version](#output\_version) | Published version of the Lambda function |
<!-- END_TF_DOCS -->
