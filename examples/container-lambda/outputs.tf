output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = module.container_lambda.lambda_function_arn
}

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = module.container_lambda.lambda_function_name
}

output "lambda_function_version" {
  description = "Version of the Lambda function"
  value       = module.container_lambda.lambda_function_version
}

output "lambda_role_arn" {
  description = "ARN of the Lambda execution role"
  value       = module.container_lambda.lambda_role_arn
}

output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.lambda_container.repository_url
}

output "ecr_repository_arn" {
  description = "ARN of the ECR repository"
  value       = aws_ecr_repository.lambda_container.arn
}

output "container_image_uri" {
  description = "URI of the container image used by Lambda"
  value       = "${aws_ecr_repository.lambda_container.repository_url}:${var.image_tag}"
}

output "docker_image_id" {
  description = "ID of the Docker image"
  value       = docker_image.lambda_container.image_id
}
