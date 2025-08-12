# Complete Lambda Example - All Features Showcase

This is the **ultimate example** that demonstrates **ALL features** of the AWS Lambda Terraform module in a single, comprehensive deployment. This example showcases every capability including VPC integration, database connectivity, dead letter queues, versioning, aliases, provisioned concurrency, multiple event sources, KMS encryption, and advanced monitoring.

## 🚀 What This Example Creates

### **Core Infrastructure**
- ✅ **RDS PostgreSQL Database** with encryption and security groups
- ✅ **KMS Key** for environment variable encryption

### **Lambda Function Features**
- ✅ **ARM64 Architecture** for better price-performance
- ✅ **VPC Integration** with private subnet deployment
- ✅ **Dead Letter Queue** with SQS for error handling
- ✅ **Versioning & Aliases** for blue-green deployments
- ✅ **Provisioned Concurrency** to eliminate cold starts
- ✅ **KMS Encryption** for environment variables
- ✅ **Lambda Insights** for advanced monitoring
- ✅ **Function URL** with CORS configuration

### **Event Sources & Integrations**
- ✅ **S3 Bucket** with object event notifications
- ✅ **SNS Topic** with Lambda subscription
- ✅ **SQS Queue** with event source mapping
- ✅ **API Gateway** with Lambda proxy integration
- ✅ **EventBridge** with scheduled invocations
- ✅ **SSM Parameter Store** with 10+ parameters

### **Monitoring & Observability**
- ✅ **CloudWatch Dashboard** with comprehensive metrics
- ✅ **CloudWatch Alarms** for errors, duration, and DLQ
- ✅ **Custom Metrics** for application-specific monitoring
- ✅ **Structured Logging** with configurable levels

## 🚀 Quick Start

### 1. **Prerequisites**
- AWS CLI configured with appropriate permissions
- Terraform >= 1.3.0 installed
- Unique S3 bucket name ready

### 2. **Configuration**
Edit `terraform.tfvars` and update:
```hcl
# REQUIRED: Change to a globally unique name
s3_bucket_name = "your-unique-complete-lambda-bucket-name"

# OPTIONAL: Add your email for notifications
notification_email = "your-email@example.com"

# OPTIONAL: Adjust costs by modifying these
provisioned_concurrent_executions = 3  # Reduce to save money
```

### 3. **Deploy**
```bash
# Initialize Terraform
terraform init

# Review the plan (will show ~30 resources)
terraform plan

# Deploy (takes 5-10 minutes)
terraform apply


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
| [aws_s3_bucket.event_source](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_notification.lambda_notification](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_notification) | resource |
| [aws_s3_bucket_public_access_block.event_source](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.event_source](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.event_source](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_sns_topic.lambda_notifications](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_sns_topic_subscription.email_notification](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription) | resource |
| [aws_sns_topic_subscription.lambda_subscription](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription) | resource |
| [aws_sqs_queue.lambda_queue](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue) | resource |
| [aws_ssm_parameter.lambda_config](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [archive_file.lambda_zip](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_subnets.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnets) | data source |
| [aws_vpc.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |
| [aws_vpc.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
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
| <a name="output_api_gateway_rest_api_id"></a> [api\_gateway\_rest\_api\_id](#output\_api\_gateway\_rest\_api\_id) | ID of the API Gateway REST API |
| <a name="output_api_gateway_url"></a> [api\_gateway\_url](#output\_api\_gateway\_url) | URL of the API Gateway endpoint |
| <a name="output_cloudwatch_dashboard_url"></a> [cloudwatch\_dashboard\_url](#output\_cloudwatch\_dashboard\_url) | URL to the CloudWatch dashboard |
| <a name="output_dead_letter_queue_arn"></a> [dead\_letter\_queue\_arn](#output\_dead\_letter\_queue\_arn) | ARN of the Dead Letter Queue |
| <a name="output_dead_letter_queue_url"></a> [dead\_letter\_queue\_url](#output\_dead\_letter\_queue\_url) | URL of the Dead Letter Queue |
| <a name="output_eventbridge_rule_name"></a> [eventbridge\_rule\_name](#output\_eventbridge\_rule\_name) | Name of the EventBridge rule |
| <a name="output_kms_key_arn"></a> [kms\_key\_arn](#output\_kms\_key\_arn) | ARN of the KMS key used for encryption |
| <a name="output_kms_key_id"></a> [kms\_key\_id](#output\_kms\_key\_id) | ID of the KMS key used for encryption |
| <a name="output_lambda_alias_arn"></a> [lambda\_alias\_arn](#output\_lambda\_alias\_arn) | ARN of the Lambda alias |
| <a name="output_lambda_alias_name"></a> [lambda\_alias\_name](#output\_lambda\_alias\_name) | Name of the Lambda alias |
| <a name="output_lambda_function_arn"></a> [lambda\_function\_arn](#output\_lambda\_function\_arn) | ARN of the Lambda function |
| <a name="output_lambda_function_name"></a> [lambda\_function\_name](#output\_lambda\_function\_name) | Name of the Lambda function |
| <a name="output_lambda_function_url"></a> [lambda\_function\_url](#output\_lambda\_function\_url) | Lambda function URL (if enabled) |
| <a name="output_lambda_function_version"></a> [lambda\_function\_version](#output\_lambda\_function\_version) | Published version of the Lambda function |
| <a name="output_lambda_insights_url"></a> [lambda\_insights\_url](#output\_lambda\_insights\_url) | URL to Lambda Insights |
| <a name="output_lambda_role_arn"></a> [lambda\_role\_arn](#output\_lambda\_role\_arn) | ARN of the Lambda execution role |
| <a name="output_s3_bucket_arn"></a> [s3\_bucket\_arn](#output\_s3\_bucket\_arn) | ARN of the S3 bucket for event source |
| <a name="output_s3_bucket_name"></a> [s3\_bucket\_name](#output\_s3\_bucket\_name) | Name of the S3 bucket for event source |
| <a name="output_sns_topic_arn"></a> [sns\_topic\_arn](#output\_sns\_topic\_arn) | ARN of the SNS topic |
| <a name="output_sqs_queue_arn"></a> [sqs\_queue\_arn](#output\_sqs\_queue\_arn) | ARN of the SQS queue |
| <a name="output_sqs_queue_url"></a> [sqs\_queue\_url](#output\_sqs\_queue\_url) | URL of the SQS queue |
| <a name="output_ssm_parameter_names"></a> [ssm\_parameter\_names](#output\_ssm\_parameter\_names) | Names of the created SSM parameters |
<!-- END_TF_DOCS -->
