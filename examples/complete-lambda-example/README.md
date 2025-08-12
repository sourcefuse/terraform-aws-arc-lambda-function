# Complete Lambda Example - All Features Showcase

This is the **ultimate example** that demonstrates **ALL features** of the AWS Lambda Terraform module in a single, comprehensive deployment. This example showcases every capability including VPC integration, database connectivity, dead letter queues, versioning, aliases, provisioned concurrency, multiple event sources, KMS encryption, and advanced monitoring.

## 🚀 What This Example Creates

### **Core Infrastructure**
- ✅ **Complete VPC** with public/private subnets across multiple AZs
- ✅ **NAT Gateways** for internet access from private subnets
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

## 🏗️ Architecture Diagram

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Internet      │───▶│   Public Subnet  │───▶│   NAT Gateway   │
│   Gateway       │    │   (Multi-AZ)     │    │   (Multi-AZ)    │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                │                        │
                                │                        │
                                ▼                        ▼
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   API Gateway   │───▶│  Private Subnet  │───▶│  Lambda Function│
│   (REST API)    │    │   (Multi-AZ)     │    │  (Complete)     │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                │                        │
┌─────────────────┐             │                        │
│   S3 Bucket     │─────────────┼────────────────────────┤
│ (Event Source)  │             │                        │
└─────────────────┘             │                        ▼
                                │               ┌─────────────────┐
┌─────────────────┐             │               │  RDS Database   │
│   SNS Topic     │─────────────┼──────────────▶│  (PostgreSQL)   │
│ (Notifications) │             │               └─────────────────┘
└─────────────────┘             │
                                │               ┌─────────────────┐
┌─────────────────┐             │               │ Dead Letter     │
│   SQS Queue     │─────────────┼──────────────▶│ Queue (SQS)     │
│ (Messages)      │             │               └─────────────────┘
└─────────────────┘             │
                                │               ┌─────────────────┐
┌─────────────────┐             │               │ SSM Parameters  │
│   EventBridge   │─────────────┼──────────────▶│ (Configuration) │
│ (Scheduled)     │             │               └─────────────────┘
└─────────────────┘             │
                                │               ┌─────────────────┐
┌─────────────────┐             │               │ CloudWatch      │
│   Function URL  │─────────────┼──────────────▶│ Metrics & Logs  │
│ (Direct HTTPS)  │             │               └─────────────────┘
└─────────────────┘             │
                                │               ┌─────────────────┐
                                └──────────────▶│ KMS Encryption  │
                                                │ (Env Variables) │
                                                └─────────────────┘
```

## 💰 Cost Breakdown (Monthly Estimates)

| Component | Estimated Cost | Notes |
|-----------|----------------|-------|
| **Lambda Function** | $0.00 | Free tier covers most usage |
| **Provisioned Concurrency** | ~$15.21 | 5 executions × 1GB × 730 hours |
| **NAT Gateway** | ~$90.00 | 2 gateways × $45 each |
| **RDS db.t3.micro** | ~$13.00 | PostgreSQL instance |
| **S3, SNS, SQS** | ~$2.00 | Minimal usage |
| **API Gateway** | ~$3.50 | Per million requests |
| **CloudWatch** | ~$5.00 | Logs, metrics, dashboards |
| **KMS** | ~$1.00 | Key usage |
| **SSM Parameters** | ~$0.50 | Parameter requests |
| **Total Estimated** | **~$130/month** | **For full production setup** |

### 💡 Cost Optimization Options
- Disable NAT Gateway (-$90): Lose internet access but save significantly
- Reduce provisioned concurrency (-$10): Accept some cold starts
- Use smaller RDS instance: db.t3.nano saves ~$5/month

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

# Confirm SNS subscription (check email if configured)
```

### 4. **Test All Features**

**Test basic functionality:**
```bash
aws lambda invoke \
  --function-name complete-lambda-example \
  --payload '{"action": "test_all_features"}' \
  response.json && cat response.json | jq .
```

**Test via alias (provisioned concurrency):**
```bash
aws lambda invoke \
  --function-name complete-lambda-example:production \
  --payload '{"action": "test_via_alias"}' \
  response.json && cat response.json | jq .
```

**Test S3 event trigger:**
```bash
echo '{"test": "s3_upload", "timestamp": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"}' > test-file.json
aws s3 cp test-file.json s3://YOUR-BUCKET-NAME/uploads/
```

**Test API Gateway:**
```bash
# Get API URL from outputs
API_URL=$(terraform output -raw api_gateway_url)
curl -X POST $API_URL -H "Content-Type: application/json" -d '{"test": "api_gateway"}'
```

**Test Function URL (if enabled):**
```bash
FUNCTION_URL=$(terraform output -raw lambda_function_url)
curl -X POST $FUNCTION_URL -H "Content-Type: application/json" -d '{"test": "function_url"}'
```

**Test SNS integration:**
```bash
aws sns publish \
  --topic-arn $(terraform output -raw sns_topic_arn) \
  --message '{"test": "sns_notification"}'
```

**Test SQS integration:**
```bash
aws sqs send-message \
  --queue-url $(terraform output -raw sqs_queue_url) \
  --message-body '{"test": "sqs_message"}'
```

### 5. **Monitor**

**View real-time logs:**
```bash
aws logs tail /aws/lambda/complete-lambda-example --follow
```

**Open CloudWatch Dashboard:**
```bash
# Dashboard URL is in terraform outputs
terraform output cloudwatch_dashboard_url
```

**Check Lambda Insights:**
```bash
# Lambda Insights URL is in terraform outputs
terraform output lambda_insights_url
```

**Monitor DLQ:**
```bash
aws sqs get-queue-attributes \
  --queue-url $(terraform output -raw dead_letter_queue_url) \
  --attribute-names ApproximateNumberOfMessages
```

### 6. **Load Testing**

**API Gateway load test:**
```bash
for i in {1..20}; do
  curl -X POST $(terraform output -raw api_gateway_url) \
    -H "Content-Type: application/json" \
    -d "{\"test_id\": \"$i\", \"test_type\": \"load\"}" &
done
wait
```

**Direct Lambda load test:**
```bash
for i in {1..50}; do
  aws lambda invoke \
    --function-name complete-lambda-example:production \
    --payload "{\"test_id\": \"$i\", \"action\": \"performance_test\"}" \
    response_$i.json &
done
wait
```

### 7. **Clean Up**
```bash
# Remove all resources and stop charges
terraform destroy
```

## 🔧 Advanced Features Demonstrated

### **1. VPC Integration**
- Lambda deployed in private subnets
- Database connectivity via security groups
- Internet access via NAT Gateway
- Network isolation and security

### **2. Blue-Green Deployments**
- Function versioning enabled
- Production alias for stable endpoint
- Weighted traffic routing capability
- Zero-downtime deployment support

### **3. Performance Optimization**
- ARM64 architecture for better price-performance
- Provisioned concurrency eliminates cold starts
- Optimized memory allocation (1GB)
- Performance monitoring and metrics

### **4. Error Handling**
- Dead Letter Queue for failed invocations
- CloudWatch alarms for error monitoring
- Comprehensive error logging
- SNS notifications for critical errors

### **5. Security Best Practices**
- KMS encryption for environment variables
- VPC deployment for network isolation
- IAM roles with least privilege
- Parameter Store for secure configuration

### **6. Multi-Source Event Processing**
- S3 object events (create/delete)
- SNS message processing
- SQS batch processing
- API Gateway HTTP requests
- EventBridge scheduled events
- Direct function URL access

### **7. Comprehensive Monitoring**
- Lambda Insights for performance analysis
- Custom CloudWatch metrics
- Structured logging with correlation IDs
- Real-time dashboards and alarms

## 📊 Function Capabilities

The Lambda function includes comprehensive handlers for:

### **Direct Actions** (via `{"action": "action_name"}`)
- `test_all_features` - Complete feature test
- `test_permissions` - AWS service permission validation
- `test_vpc` - VPC connectivity and internet access
- `test_database` - Database connectivity test
- `get_ssm_parameters` - Retrieve all configuration
- `test_via_alias` - Alias invocation test
- `performance_test` - CPU/memory performance test

### **Event Source Processing**
- **S3 Events**: Object metadata extraction, SNS notifications
- **SNS Events**: Message parsing, SQS forwarding
- **SQS Events**: Batch message processing
- **API Gateway**: HTTP request/response handling
- **EventBridge**: Scheduled maintenance tasks

### **Built-in Monitoring**
- Cold start detection and metrics
- Execution time tracking
- Custom CloudWatch metrics
- Error categorization and alerting

## 🛠️ Customization Options

### **Scaling Configuration**
```hcl
# Adjust based on your needs
memory_size = 2048  # More memory for CPU-intensive tasks
timeout = 120       # Longer timeout for complex operations
provisioned_concurrent_executions = 10  # Higher concurrency
```

### **Cost Optimization**
```hcl
# Reduce costs
memory_size = 512   # Lower memory
provisioned_concurrent_executions = 2  # Minimal concurrency
# Set create_nat_gateway = false in main.tf to save $90/month
```

### **Security Hardening**
```hcl
# Enhanced security
log_retention_days = 90  # Longer log retention
# Add additional SSM parameters for secrets
# Configure VPC endpoints to avoid NAT Gateway
```

## 🔍 Troubleshooting

### **Common Issues**

1. **S3 Bucket Name Conflict**
   - Error: "BucketAlreadyExists"
   - Solution: Change `s3_bucket_name` to a globally unique value

2. **High Costs**
   - Issue: Unexpected AWS charges
   - Solution: Monitor NAT Gateway and provisioned concurrency usage

3. **Lambda Timeout in VPC**
   - Issue: Function times out
   - Solution: Increase timeout, check NAT Gateway connectivity

4. **Database Connection Fails**
   - Issue: Cannot connect to RDS
   - Solution: Verify security group rules and VPC configuration

### **Debugging Commands**

```bash
# Check function configuration
aws lambda get-function --function-name complete-lambda-example

# Check VPC configuration
aws lambda get-function --function-name complete-lambda-example \
  --query 'Configuration.VpcConfig'

# Check provisioned concurrency
aws lambda get-provisioned-concurrency-config \
  --function-name complete-lambda-example \
  --qualifier production

# Monitor costs
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-01-31 \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=SERVICE
```

## 🎯 Use Cases

This complete example is perfect for:

### **Learning & Training**
- Understanding all Lambda features
- AWS architecture best practices
- Infrastructure as Code patterns
- Monitoring and observability

### **Production Templates**
- Enterprise Lambda deployments
- Multi-environment setups
- Compliance and security requirements
- Performance-critical applications

### **Proof of Concepts**
- Demonstrating AWS capabilities
- Architecture validation
- Cost estimation and planning
- Feature evaluation

## 🚀 Next Steps

After exploring this complete example:

1. **Customize for your needs** - Modify variables and configuration
2. **Add your application code** - Replace the example Lambda function
3. **Implement CI/CD** - Add deployment pipelines
4. **Add more event sources** - Integrate with additional AWS services
5. **Optimize costs** - Monitor usage and adjust resources
6. **Scale up** - Add more environments and regions

## 📚 Related Examples

- [Basic Lambda](../basic-lambda/) - Simple starting point
- [VPC Lambda](../lambda-in-vpc/) - Focus on networking
- [Container Lambda](../container-lambda/) - Docker deployment
- [Lambda with DLQ](../lambda-with-dlq/) - Error handling focus

---

**This complete example showcases the full power and flexibility of the AWS Lambda Terraform module. It's designed to be both educational and production-ready, demonstrating every feature while following AWS best practices.**
