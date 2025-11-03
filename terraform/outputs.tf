output "images_bucket_name" {
  description = "Name of the S3 bucket for images"
  value       = aws_s3_bucket.images.bucket
}

output "lambda_artifacts_bucket_name" {
  description = "Name of the S3 bucket for Lambda artifacts"
  value       = aws_s3_bucket.lambda_artifacts.bucket
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table"
  value       = aws_dynamodb_table.image_metadata.name
}

output "lambda_role_arn" {
  description = "ARN of the Lambda IAM role"
  value       = aws_iam_role.lambda_role.arn
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.image_analyzer.arn
}

output "github_actions_role_arn" {
  description = "ARN of the GitHub Actions IAM role"
  value       = aws_iam_role.github_actions.arn
}