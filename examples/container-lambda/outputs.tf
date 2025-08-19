output "arn" {
  description = "ARN of the Lambda function"
  value       = module.container_lambda.arn
}

output "name" {
  description = "Name of the Lambda function"
  value       = module.container_lambda.name
}

output "version" {
  description = "Version of the Lambda function"
  value       = module.container_lambda.version
}
