# Container Lambda Function Example

This example demonstrates how to deploy an AWS Lambda function using container images with the Lambda Terraform module. The function showcases advanced features like external API calls, parameter store integration, and structured logging.

## What This Example Creates

- ECR repository for container images with lifecycle policies
- Docker image built from local Dockerfile
- AWS Lambda function using container image deployment
- IAM role with ECR and SSM permissions
- CloudWatch log group with 30-day retention

## Features Demonstrated

- Container-based Lambda deployment
- ECR repository management with lifecycle policies
- Docker image building and pushing via Terraform
- Advanced Python application with dependencies
- External API integration
- AWS Systems Manager Parameter Store integration
- Structured logging with JSON output
- Pydantic for request/response validation
- Multiple action handlers

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Dockerfile    │───▶│   ECR Repository │───▶│  Lambda Function│
│   (builds)      │    │  (stores image)  │    │  (executes)     │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                       │                        │
         │                       │                        │
         ▼                       ▼                        ▼
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│  Python App +   │    │  Image Lifecycle │    │ CloudWatch Logs │
│  Dependencies   │    │     Policies     │    │   (30 days)     │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

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

5. **Test the function with different actions:**

   **Health Check:**
   ```bash
   aws lambda invoke \
     --function-name container-lambda-example \
     --payload '{"action": "health"}' \
     response.json && cat response.json | jq .
   ```

   **Echo Test:**
   ```bash
   aws lambda invoke \
     --function-name container-lambda-example \
     --payload '{"action": "echo", "payload": {"message": "Hello Container Lambda!"}}' \
     response.json && cat response.json | jq .
   ```

   **External API Call:**
   ```bash
   aws lambda invoke \
     --function-name container-lambda-example \
     --payload '{"action": "external_api", "payload": {"url": "https://httpbin.org/json"}}' \
     response.json && cat response.json | jq .
   ```

   **Parameter Store Demo:**
   ```bash
   aws lambda invoke \
     --function-name container-lambda-example \
     --payload '{"action": "parameter_demo"}' \
     response.json && cat response.json | jq .
   ```

6. **Clean up:**
   ```bash
   terraform destroy
   ```

## Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `aws_region` | AWS region for resources | `us-east-1` |
| `function_name` | Name of the Lambda function | `container-lambda-example` |
| `ecr_repository_name` | ECR repository name | `lambda-container-example` |
| `image_tag` | Container image tag | `v1.0.0` |
| `environment` | Environment name | `dev` |
| `log_level` | Log level for the function | `INFO` |

## Container Image Details

### Base Image
- Uses `public.ecr.aws/lambda/python:3.11` (official AWS Lambda Python runtime)
- Optimized for Lambda execution environment
- Includes Lambda Runtime Interface Client

### Dependencies
- **boto3/botocore**: AWS SDK for Python
- **requests**: HTTP library for external API calls
- **pydantic**: Data validation and settings management
- **python-json-logger**: Structured JSON logging

### Build Process
1. **Dockerfile**: Defines the container image
2. **Requirements**: Installs Python dependencies
3. **Application Code**: Copies the main application
4. **Configuration**: Sets environment variables and handler

## Function Actions

The Lambda function supports multiple actions:

### 1. Health Check (`health`)
Returns system information and health status:
```json
{
  "action": "health"
}
```

### 2. Echo (`echo`)
Echoes back the provided payload:
```json
{
  "action": "echo",
  "payload": {"message": "test"}
}
```

### 3. External API (`external_api`)
Makes HTTP requests to external APIs:
```json
{
  "action": "external_api",
  "payload": {"url": "https://httpbin.org/json"}
}
```

### 4. Parameter Demo (`parameter_demo`)
Demonstrates AWS Systems Manager Parameter Store integration:
```json
{
  "action": "parameter_demo"
}
```

## ECR Repository Configuration

The ECR repository includes:

- **Image Scanning**: Enabled for security vulnerability detection
- **Lifecycle Policies**:
  - Keep last 10 tagged images
  - Delete untagged images after 1 day
- **Mutable Tags**: Allows tag updates for development

## IAM Permissions

The Lambda function has permissions for:

- **ECR Access**: Pull container images
- **SSM Access**: Read parameters from Parameter Store
- **CloudWatch Logs**: Write function logs

## Local Development

You can test the function locally:

```bash
cd examples/container-lambda
python app.py
```

This runs the function with mock events and context.

## Monitoring and Debugging

### CloudWatch Logs
```bash
aws logs tail /aws/lambda/container-lambda-example --follow
```

### Container Image Information
```bash
# List images in ECR
aws ecr list-images --repository-name lambda-container-example

# Get image details
aws ecr describe-images --repository-name lambda-container-example
```

### Function Configuration
```bash
aws lambda get-function --function-name container-lambda-example
```

## Cost Considerations

- **ECR Storage**: Container image storage costs
- **Lambda Execution**: 512MB memory allocation
- **CloudWatch Logs**: 30-day retention
- **ECR Data Transfer**: Image pulls during cold starts

Estimated monthly cost for moderate usage: $3-8 USD

## Troubleshooting

### Common Issues

1. **Docker Build Failures**: Ensure Docker is running and has sufficient resources
2. **ECR Push Failures**: Verify AWS credentials and ECR permissions
3. **Lambda Cold Starts**: Container images have longer cold start times
4. **Image Size**: Keep images under 10GB limit

### Build Optimization

- Use multi-stage builds to reduce image size
- Leverage Docker layer caching
- Minimize the number of RUN commands
- Use `.dockerignore` to exclude unnecessary files

## Advanced Features

### Custom Parameters
Create parameters in SSM Parameter Store:
```bash
aws ssm put-parameter \
  --name "/container-lambda-example/config/demo_setting" \
  --value "custom_value" \
  --type "String"
```

### Image Updates
To update the function with a new image:
1. Modify the code
2. Update `image_tag` in `terraform.tfvars`
3. Run `terraform apply`

## Next Steps

- [Lambda with Alias](../lambda-with-alias/) - Versioning and aliases
- [Lambda with Provisioned Concurrency](../lambda-with-provisioned-concurrency/) - Performance optimization
- [Lambda in VPC](../lambda-in-vpc/) - Network isolation
- [Lambda with DLQ](../lambda-with-dlq/) - Error handling
