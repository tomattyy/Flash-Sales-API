variable "aws_region" {
  description = "AWS region used by LocalStack."
  type        = string
  default     = "us-east-1"
}

variable "localstack_endpoint" {
  description = "S3-compatible LocalStack endpoint."
  type        = string
  default     = "http://localhost:4566"
}

provider "aws" {
  region                      = var.aws_region
  s3_use_path_style           = true
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    s3 = var.localstack_endpoint
  }
}
