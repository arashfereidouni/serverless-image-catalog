# Serverless Image Catalog

A serverless image analysis application that automatically processes uploaded images using AWS Rekognition and stores metadata in DynamoDB.

## Architecture

- **S3 Bucket**: Stores original images with event notifications
- **Lambda Function**: Processes images using AWS Rekognition
- **DynamoDB**: Stores image metadata and AI-generated labels
- **IAM Roles**: Secure permissions for S3, DynamoDB, and Rekognition access

## Prerequisites

- AWS CLI configured
- Terraform >= 1.0
- Python 3.9+

## Deployment

### 1. Create Terraform State Bucket
```bash
aws s3 mb s3://serverless-image-catalog-terraform-state --region us-east-1
aws s3api put-bucket-versioning --bucket serverless-image-catalog-terraform-state --versioning-configuration Status=Enabled
```

### 2. Deploy Infrastructure
```bash
cd terraform
terraform init
terraform apply
```

## Usage

Upload images to trigger automatic analysis:
```bash
aws s3 cp your-image.jpg s3://[images-bucket-name]/
```

Query results from DynamoDB:
```bash
aws dynamodb scan --table-name serverless-image-catalog-image-metadata
```

## CI/CD Setup

### 1. Deploy OIDC Role
```bash
cd terraform
terraform apply
```

### 2. Configure GitHub Secrets
Add the GitHub Actions role ARN to repository secrets:
```
AWS_ROLE_ARN=<github_actions_role_arn_from_terraform_output>
```

### 3. Automatic Deployment
Push to main branch triggers automatic deployment via GitHub Actions.

## Resources Created

- S3 buckets for images and Lambda artifacts
- Lambda function with Rekognition integration
- DynamoDB table for metadata storage
- IAM roles with least-privilege permissions
- GitHub Actions OIDC role for secure CI/CD
