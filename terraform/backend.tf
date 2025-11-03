terraform {
  backend "s3" {
    bucket = "serverless-image-catalog-terraform-state"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}