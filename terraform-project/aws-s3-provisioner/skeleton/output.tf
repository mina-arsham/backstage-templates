output "bucket_name" {
  description = "The name of the S3 bucket"
  value       = aws_s3_bucket.main.id
}

output "bucket_arn" {
  description = "The ARN of the S3 bucket"
  value       = aws_s3_bucket.main.arn
}

output "bucket_region" {
  description = "The AWS region where the bucket is created"
  value       = aws_s3_bucket.main.region
}

output "bucket_domain_name" {
  description = "The bucket domain name"
  value       = aws_s3_bucket.main.bucket_domain_name
}

output "bucket_regional_domain_name" {
  description = "The bucket region-specific domain name"
  value       = aws_s3_bucket.main.bucket_regional_domain_name
}

output "versioning_enabled" {
  description = "Whether versioning is enabled"
  value       = "${{ values.enable_versioning }}"
}

output "encryption_type" {
  description = "The type of encryption used"
  value       = "${{ values.encryption_type }}"
}

{%- if values.enable_static_website %}

output "website_endpoint" {
  description = "The website endpoint"
  value       = aws_s3_bucket_website_configuration.main.website_endpoint
}
{%- endif %}

{%- if values.enable_access_logging %}

output "log_bucket_name" {
  description = "The name of the logging bucket"
  value       = aws_s3_bucket.log_bucket.id
}
{%- endif %}

output "environment" {
  description = "The deployment environment"
  value       = "${{ values.environment }}"
}

output "project_name" {
  description = "The project name"
  value       = "${{ values.project_name }}"
}

output "bucket_policy_type" {
  description = "The type of bucket policy applied"
  value       = "${{ values.bucket_policy_type }}"
}

{%- if values.bucket_policy_type != "none" %}

output "bucket_policy_applied" {
  description = "Whether a bucket policy was applied"
  value       = true
}
{%- endif %}

output "mfa_delete_enabled" {
  description = "Whether MFA delete is enabled"
  value       = "${{ values.require_mfa_delete and values.enable_versioning }}"
}

output "tags" {
  description = "All tags applied to the bucket"
  value       = local.common_tags
}
