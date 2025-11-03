provider "aws" {
  region = var.aws_region
}

# S3 bucket for original images
resource "aws_s3_bucket" "images" {
  bucket = "${var.project_name}-images-${random_id.bucket_suffix.hex}"
}

resource "aws_s3_bucket_versioning" "images" {
  bucket = aws_s3_bucket.images.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 bucket for Lambda deployment artifacts
resource "aws_s3_bucket" "lambda_artifacts" {
  bucket = "${var.project_name}-lambda-artifacts-${random_id.bucket_suffix.hex}"
}

resource "aws_s3_bucket_versioning" "lambda_artifacts" {
  bucket = aws_s3_bucket.lambda_artifacts.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Random ID for unique bucket names
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# DynamoDB table for image metadata
resource "aws_dynamodb_table" "image_metadata" {
  name           = "${var.project_name}-image-metadata"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "image_id"

  attribute {
    name = "image_id"
    type = "S"
  }

  tags = {
    Name = "${var.project_name}-image-metadata"
  }
}

# IAM role for Lambda function
resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# IAM policy for Lambda function
resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.project_name}-lambda-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = [
          "${aws_s3_bucket.images.arn}/*",
          "${aws_s3_bucket.lambda_artifacts.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = aws_dynamodb_table.image_metadata.arn
      },
      {
        Effect = "Allow"
        Action = [
          "rekognition:DetectLabels",
          "rekognition:DetectFaces",
          "rekognition:DetectText",
          "rekognition:RecognizeCelebrities"
        ]
        Resource = "*"
      }
    ]
  })
}

# Lambda deployment package
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "../lambda/image_analyzer.py"
  output_path = "../lambda/image_analyzer.zip"
}

# Lambda function
resource "aws_lambda_function" "image_analyzer" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.project_name}-image-analyzer"
  role            = aws_iam_role.lambda_role.arn
  handler         = "image_analyzer.lambda_handler"
  runtime         = "python3.9"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.image_metadata.name
    }
  }
}

# S3 bucket notification
resource "aws_s3_bucket_notification" "image_upload" {
  bucket = aws_s3_bucket.images.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.image_analyzer.arn
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = ".jpg"
  }

  lambda_function {
    lambda_function_arn = aws_lambda_function.image_analyzer.arn
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = ".png"
  }

  depends_on = [aws_lambda_permission.s3_invoke]
}

# Lambda permission for S3 to invoke function
resource "aws_lambda_permission" "s3_invoke" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.image_analyzer.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.images.arn
}