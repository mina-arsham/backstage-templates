terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "${{ values.aws_region }}"
}

# Generate a unique bucket name
locals {
  bucket_name = "${{ values.project_name }}-${{ values.environment }}-${random_string.bucket_suffix.result}"
  
  common_tags = {
    Name        = local.bucket_name
    Environment = "${{ values.environment }}"
    Owner       = "${{ values.owner_email }}"
    CostCenter  = "${{ values.cost_center }}"
    ManagedBy   = "Terraform"
    Project     = "${{ values.project_name }}"
    CreatedAt   = timestamp()
{%- if values.additional_tags %}
{%- for key, value in values.additional_tags %}
    {{ key }} = "{{ value }}"
{%- endfor %}
{%- endif %}
  }
}

# Random suffix to ensure globally unique bucket name
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

# S3 Bucket
resource "aws_s3_bucket" "main" {
  bucket = local.bucket_name
  
  tags = local.common_tags
}

# Versioning
resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id
  
  versioning_configuration {
    status     = "${{ values.enable_versioning }}" == "true" ? "Enabled" : "Disabled"
    mfa_delete = "${{ values.require_mfa_delete }}" == "true" && "${{ values.enable_versioning }}" == "true" ? "Enabled" : "Disabled"
  }
}

# Server-Side Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "${{ values.encryption_type }}" == "AES256" ? "AES256" : "aws:kms"
    }
    bucket_key_enabled = "${{ values.encryption_type }}" != "AES256"
  }
}

# Block Public Access
resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = "${{ values.block_public_access }}"
  block_public_policy     = "${{ values.block_public_access }}"
  ignore_public_acls      = "${{ values.block_public_access }}"
  restrict_public_buckets = "${{ values.block_public_access }}"
}

{%- if values.enable_access_logging %}

# Access Logging Bucket
resource "aws_s3_bucket" "log_bucket" {
  bucket = "${local.bucket_name}-logs"
  
  tags = merge(
    local.common_tags,
    {
      Name = "${local.bucket_name}-logs"
      Type = "AccessLogs"
    }
  )
}

resource "aws_s3_bucket_logging" "main" {
  bucket = aws_s3_bucket.main.id

  target_bucket = aws_s3_bucket.log_bucket.id
  target_prefix = "log/"
}
{%- endif %}

{%- if values.enable_lifecycle_policy %}

# Lifecycle Policy
resource "aws_s3_bucket_lifecycle_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    id     = "transition-and-expiration"
    status = "Enabled"

    transition {
      days          = "${{ values.lifecycle_transition_days }}"
      storage_class = "STANDARD_IA"
    }

{%- if values.lifecycle_expiration_days > 0 %}
    expiration {
      days = "${{ values.lifecycle_expiration_days }}"
    }
{%- endif %}

    noncurrent_version_transition {
      noncurrent_days = "${{ values.lifecycle_transition_days + 30 }}"
      storage_class   = "GLACIER"
    }

{%- if values.lifecycle_expiration_days > 0 %}
    noncurrent_version_expiration {
      noncurrent_days = "${{ values.lifecycle_expiration_days + 30 }}"
    }
{%- endif %}
  }
}
{%- endif %}

{%- if values.enable_cors %}

# CORS Configuration
resource "aws_s3_bucket_cors_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD", "PUT", "POST"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}
{%- endif %}

{%- if values.enable_static_website %}

# Static Website Hosting
resource "aws_s3_bucket_website_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}
{%- endif %}

{%- if values.bucket_policy_type != "none" %}

# Bucket Policy
resource "aws_s3_bucket_policy" "main" {
  bucket = aws_s3_bucket.main.id

{%- if values.bucket_policy_type == "custom" %}
  policy = <<POLICY
${{ values.custom_policy_json }}
POLICY
{%- else %}
  policy = data.aws_iam_policy_document.bucket_policy.json
{%- endif %}
  
  depends_on = [aws_s3_bucket_public_access_block.main]
}

{%- if values.bucket_policy_type != "custom" %}

# Data source for generating bucket policies based on type
data "aws_iam_policy_document" "bucket_policy" {

{%- if values.bucket_policy_type == "read_only" %}
  # Public Read-Only Access
  statement {
    sid    = "PublicReadGetObject"
    effect = "Allow"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = [
      "s3:GetObject"
    ]
    resources = [
      "${aws_s3_bucket.main.arn}/*"
    ]
  }
{%- endif %}

{%- if values.bucket_policy_type == "cloudfront_oac" and values.cloudfront_distribution_arn %}
  # CloudFront Origin Access Control (OAC)
  statement {
    sid    = "AllowCloudFrontServicePrincipal"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    actions = [
      "s3:GetObject"
    ]
    resources = [
      "${aws_s3_bucket.main.arn}/*"
    ]
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = ["${{ values.cloudfront_distribution_arn }}"]
    }
  }
{%- endif %}

{%- if values.bucket_policy_type == "vpc_endpoint" and values.vpc_endpoint_id %}
  # VPC Endpoint Restriction - Allow
  statement {
    sid    = "AllowVPCEndpointAccess"
    effect = "Allow"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket"
    ]
    resources = [
      aws_s3_bucket.main.arn,
      "${aws_s3_bucket.main.arn}/*"
    ]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceVpce"
      values   = ["${{ values.vpc_endpoint_id }}"]
    }
  }

  # VPC Endpoint Restriction - Deny
  statement {
    sid    = "DenyNonVPCEndpointAccess"
    effect = "Deny"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = [
      "s3:*"
    ]
    resources = [
      aws_s3_bucket.main.arn,
      "${aws_s3_bucket.main.arn}/*"
    ]
    condition {
      test     = "StringNotEquals"
      variable = "aws:SourceVpce"
      values   = ["${{ values.vpc_endpoint_id }}"]
    }
  }
{%- endif %}

{%- if values.bucket_policy_type == "specific_accounts" and values.allowed_aws_accounts %}
  # Cross-Account Access
  statement {
    sid    = "AllowCrossAccountAccess"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [
{%- for account in values.allowed_aws_accounts %}
        "arn:aws:iam::{{ account }}:root"{{ "," if not loop.last else "" }}
{%- endfor %}
      ]
    }
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket",
      "s3:DeleteObject"
    ]
    resources = [
      aws_s3_bucket.main.arn,
      "${aws_s3_bucket.main.arn}/*"
    ]
  }
{%- endif %}

  # Require SSL/TLS (Deny non-HTTPS) - Applied to all policy types except custom
  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = [
      "s3:*"
    ]
    resources = [
      aws_s3_bucket.main.arn,
      "${aws_s3_bucket.main.arn}/*"
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

{%- if values.bucket_policy_type == "require_ssl" %}
  # Require SSL/TLS - Allow statement
  statement {
    sid    = "AllowSSLRequestsOnly"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions = [
      "s3:*"
    ]
    resources = [
      aws_s3_bucket.main.arn,
      "${aws_s3_bucket.main.arn}/*"
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["true"]
    }
  }
{%- endif %}
}
{%- endif %}
{%- endif %}
