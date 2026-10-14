output "exports_bucket_name" {
  description = "LocalStack bucket reserved for future API export persistence."
  value       = aws_s3_bucket.exports.id
}

output "s3_endpoint" {
  description = "LocalStack S3 endpoint."
  value       = var.localstack_endpoint
}
