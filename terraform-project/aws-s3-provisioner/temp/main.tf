# DEBUG: Passed values
# Project: ${{ values.project_name }}
# Environment: ${{ values.environment }}
# Policy Type: ${{ values.bucket_policy_type }}
# Accounts: ${{ values.allowed_aws_accounts | dump }}
# Additional tag: ${{ values.additional_tags | dump }}
terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "aws" {
  region = "${{ values.aws_region }}"
}

# Generate a unique bucket name
locals {
  bucket_name = "${{ values.project_name }}-${{ values.environment }}-${random_string.bucket_suffix.result}"
  
  common_tags = merge(
    {
      Name        = local.bucket_name
      Environment = "${{ values.environment }}"
      Owner       = "${{ values.owner_email }}"
      CostCenter  = "${{ values.cost_center }}"
      ManagedBy   = "Terraform"
      Project     = "${{ values.project_name }}"
    },
    ${{ values.additional_tags | dump }}
  )
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
    status     = "{% if values.enable_versioning %}Enabled{% else %}Disabled{% endif %}"
    mfa_delete = "{% if values.require_mfa_delete and values.enable_versioning %}Enabled{% else %}Disabled{% endif %}"
  }
}

# Server-Side Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id

{% if values.encryption_type == "AES256" %}

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
{%- elif values.encryption_type == "aws:kms" -%}
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
    bucket_key_enabled = true
  }
{%- elif values.encryption_type == "aws:kms:dsse" -%}
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms:dsse"
    }
    bucket_key_enabled = true
  }
{%- endif %}
}

# Block Public Access
resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = {% if values.block_public_access %}true{% else %}false{% endif %}
  block_public_policy     = {% if values.block_public_access %}true{% else %}false{% endif %}
  ignore_public_acls      = {% if values.block_public_access %}true{% else %}false{% endif %}
  restrict_public_buckets = {% if values.block_public_access %}true{% else %}false{% endif %}
}

{%- if values.enable_static_website %}

#############################
# Advanced Features (Optional)
#############################
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

################################
# S3 Bucket Policy (Optional)
################################
{%- if values.bucket_policy_type != "none" %}

resource "aws_s3_bucket_policy" "main" {
  bucket = aws_s3_bucket.main.id
  policy = data.aws_iam_policy_document.bucket_policy.json
  depends_on = [aws_s3_bucket_public_access_block.main]
}

data "aws_iam_policy_document" "bucket_policy" {

################################
# Read-Only (Public GetObject)
################################

{%- if values.bucket_policy_type == "read_only" %}

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

################################
# Cross-Account Access
################################

{%- if values.bucket_policy_type == "specific_accounts" and values.allowed_aws_accounts and (values.allowed_aws_accounts | length) > 0 %}

  statement {
    sid    = "AllowCrossAccountAccess"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [
{%- for acct in values.allowed_aws_accounts %}
        "arn:aws:iam::${{ acct }}:root"{% if not loop.last %},{% endif %}

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

}
{%- endif %}
