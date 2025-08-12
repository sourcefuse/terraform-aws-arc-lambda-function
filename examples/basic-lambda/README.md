# Basic Lambda Function Example

This example demonstrates how to create a simple AWS Lambda function using the Lambda Terraform module. The function is deployed from local source code and includes basic logging and environment variable configuration.

## What This Example Creates

- AWS Lambda function with Python 3.11 runtime
- IAM role with basic Lambda execution permissions
- CloudWatch log group with 7-day retention
- Simple Python function that returns a JSON response

## Features Demonstrated

- Local source code deployment using `archive_file` data source
- Environment variables configuration
- Basic CloudWatch logging setup
- Minimal IAM permissions
- Resource tagging

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

## Configuration

The example can be customized by modifying the variables in `terraform.tfvars`:

| Variable | Description | Default |
|----------|-------------|---------|
| `aws_region` | AWS region for resources | `us-east-1` |
| `function_name` | Name of the Lambda function | `basic-lambda-example` |
| `environment` | Environment name | `dev` |
| `log_level` | Log level for the function | `INFO` |
| `lambda_message` | Message returned by the function | `Hello from Basic Lambda!` |

## Function Code

The Lambda function (`lambda_function.py`) is a simple Python function that:

- Logs the incoming event
- Reads environment variables
- Returns a JSON response with function metadata
- Includes proper error handling and logging

## Expected Output

When invoked, the function returns a response like:

```json
{
  "statusCode": 200,
  "headers": {
    "Content-Type": "application/json",
    "Access-Control-Allow-Origin": "*"
  },
  "body": "{\"message\":\"Hello from Basic Lambda Example!\",\"environment\":\"dev\",\"function_name\":\"basic-lambda-example\",\"function_version\":\"$LATEST\",\"request_id\":\"12345678-1234-1234-1234-123456789012\",\"event\":{\"test\":\"data\"}}"
}
```

## Cost Considerations

This example uses minimal resources:
- Lambda function with 128MB memory
- CloudWatch logs with 7-day retention
- No provisioned concurrency or additional features

Estimated monthly cost for light usage: < $1 USD

## Next Steps

After running this basic example, you can explore more advanced features:

- [S3 Lambda Example](../s3-lambda/) - Deploy from S3
- [Container Lambda Example](../container-lambda/) - Use container images
- [Lambda with VPC](../lambda-in-vpc/) - VPC configuration
- [Lambda with DLQ](../lambda-with-dlq/) - Error handling
