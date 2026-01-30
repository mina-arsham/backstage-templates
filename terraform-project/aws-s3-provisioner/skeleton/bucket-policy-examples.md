# S3 Bucket Policy Examples

This document provides detailed examples for each bucket policy type available in the Backstage template.

## 📋 Policy Type Overview

| Policy Type | Use Case | Security Level | Public Access Required |
|------------|----------|----------------|----------------------|
| None | No policy needed | Standard | No |
| Public Read | Public website/downloads | Low ⚠️ | Yes |
| CloudFront OAC | CDN distribution | High | No |
| VPC Endpoint | Private network only | Very High | No |
| Cross-Account | Multi-account architecture | Medium | No |
| Require SSL | Enforce encryption in transit | High | No |
| Custom | Specific requirements | Varies | Varies |

---

## 1️⃣ None - No Bucket Policy

**When to use:**
- Internal buckets with IAM-based access control
- No special access requirements
- Rely on bucket ACLs and IAM policies

**Configuration:**
```yaml
bucket_policy_type: none
```

**Generated Terraform:**
```hcl
# No bucket policy resource created
```

---

## 2️⃣ Public Read - Allow Public Access

**When to use:**
- Public website hosting
- Public downloads/assets
- Open datasets

⚠️ **WARNING:** This makes your bucket publicly accessible!

**Configuration:**
```yaml
bucket_policy_type: read_only
block_public_access: false  # Must be disabled!
```

**Generated Policy:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::your-bucket/*"
    },
    {
      "Sid": "DenyInsecureTransport",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::your-bucket",
        "arn:aws:s3:::your-bucket/*"
      ],
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
```

**Use Cases:**
- Static website hosting
- Public documentation
- Open-source package repository
- Public image/video assets

---

## 3️⃣ CloudFront OAC - Origin Access Control

**When to use:**
- Serving content through CloudFront CDN
- Want bucket to be private but accessible via CloudFront
- Modern replacement for Origin Access Identity (OAI)

**Configuration:**
```yaml
bucket_policy_type: cloudfront_oac
cloudfront_distribution_arn: "arn:aws:cloudfront::123456789012:distribution/E1ABCDEFGHIJK"
block_public_access: true
```

**Generated Policy:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowCloudFrontServicePrincipal",
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudfront.amazonaws.com"
      },
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::your-bucket/*",
      "Condition": {
        "StringEquals": {
          "AWS:SourceArn": "arn:aws:cloudfront::123456789012:distribution/E1ABCDEFGHIJK"
        }
      }
    },
    {
      "Sid": "DenyInsecureTransport",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::your-bucket",
        "arn:aws:s3:::your-bucket/*"
      ],
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
```

**Steps to use:**
1. Create CloudFront distribution with OAC
2. Get the distribution ARN
3. Configure the bucket policy with the ARN
4. Bucket remains private, accessible only through CloudFront

**Use Cases:**
- Global content delivery
- DDoS protection via CloudFront
- Edge caching for performance
- Private S3 with public CloudFront URL

---

## 4️⃣ VPC Endpoint - Restrict to VPC

**When to use:**
- Internal applications within VPC
- Prevent internet exposure entirely
- Compliance requirements (HIPAA, PCI-DSS)

**Configuration:**
```yaml
bucket_policy_type: vpc_endpoint
vpc_endpoint_id: "vpce-1a2b3c4d5e6f7g8h9"
block_public_access: true
```

**Generated Policy:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowVPCEndpointAccess",
      "Effect": "Allow",
      "Principal": "*",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::your-bucket",
        "arn:aws:s3:::your-bucket/*"
      ],
      "Condition": {
        "StringEquals": {
          "aws:SourceVpce": "vpce-1a2b3c4d5e6f7g8h9"
        }
      }
    },
    {
      "Sid": "DenyNonVPCEndpointAccess",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::your-bucket",
        "arn:aws:s3:::your-bucket/*"
      ],
      "Condition": {
        "StringNotEquals": {
          "aws:SourceVpce": "vpce-1a2b3c4d5e6f7g8h9"
        }
      }
    },
    {
      "Sid": "DenyInsecureTransport",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::your-bucket",
        "arn:aws:s3:::your-bucket/*"
      ],
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
```

**Prerequisites:**
1. Create VPC Endpoint for S3:
   ```bash
   aws ec2 create-vpc-endpoint \
     --vpc-id vpc-xxxxxxxx \
     --service-name com.amazonaws.us-east-1.s3 \
     --route-table-ids rtb-xxxxxxxx
   ```
2. Note the VPC Endpoint ID (vpce-xxxxxxxxx)
3. Use it in the template

**Use Cases:**
- Private data lakes
- Internal application data
- Compliance-regulated data
- Prevent data exfiltration

---

## 5️⃣ Cross-Account Access - Share with Other AWS Accounts

**When to use:**
- Multi-account AWS Organizations
- Partner/vendor access
- Centralized logging buckets
- Cross-account backups

**Configuration:**
```yaml
bucket_policy_type: specific_accounts
allowed_aws_accounts:
  - "123456789012"
  - "210987654321"
  - "555666777888"
```

**Generated Policy:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowCrossAccountAccess",
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "arn:aws:iam::123456789012:root",
          "arn:aws:iam::210987654321:root",
          "arn:aws:iam::555666777888:root"
        ]
      },
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:ListBucket",
        "s3:DeleteObject"
      ],
      "Resource": [
        "arn:aws:s3:::your-bucket",
        "arn:aws:s3:::your-bucket/*"
      ]
    },
    {
      "Sid": "DenyInsecureTransport",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::your-bucket",
        "arn:aws:s3:::your-bucket/*"
      ],
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
```

**Access from other accounts:**
```hcl
# In the allowed account, users can assume a role or use IAM policies
data "aws_s3_bucket" "shared" {
  bucket = "your-bucket-name"
}

resource "aws_s3_object" "upload" {
  bucket = data.aws_s3_bucket.shared.id
  key    = "my-file.txt"
  source = "local-file.txt"
}
```

**Use Cases:**
- AWS Organizations multi-account strategy
- Centralized logging (send logs from multiple accounts)
- Shared data repositories
- Cross-account CI/CD pipelines

---

## 6️⃣ Require SSL/TLS - Enforce Encrypted Transport

**When to use:**
- Security best practice (recommended for ALL buckets!)
- Compliance requirements
- Prevent man-in-the-middle attacks

**Configuration:**
```yaml
bucket_policy_type: require_ssl
```

**Generated Policy:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyInsecureTransport",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::your-bucket",
        "arn:aws:s3:::your-bucket/*"
      ],
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    },
    {
      "Sid": "AllowSSLRequestsOnly",
      "Effect": "Allow",
      "Principal": {
        "AWS": "*"
      },
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::your-bucket",
        "arn:aws:s3:::your-bucket/*"
      ],
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "true"
        }
      }
    }
  ]
}
```

**Effect:**
- ✅ HTTPS requests: Allowed
- ❌ HTTP requests: Denied

**Best Practice:**
This policy is **automatically added** to all other policy types (except "none" and "custom") for defense in depth!

**Use Cases:**
- Every production bucket
- Compliance (PCI-DSS, HIPAA, SOC2)
- Prevent credential interception
- Meet security standards

---

## 7️⃣ Custom Policy - Bring Your Own

**When to use:**
- Complex requirements not covered by templates
- Specific conditions (IP restrictions, time-based, etc.)
- Integration with third-party services

**Configuration:**
```yaml
bucket_policy_type: custom
custom_policy_json: |
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "IPRestriction",
        "Effect": "Deny",
        "Principal": "*",
        "Action": "s3:*",
        "Resource": [
          "arn:aws:s3:::your-bucket",
          "arn:aws:s3:::your-bucket/*"
        ],
        "Condition": {
          "NotIpAddress": {
            "aws:SourceIp": [
              "203.0.113.0/24",
              "198.51.100.0/24"
            ]
          }
        }
      }
    ]
  }
```

**Example: IP Restriction**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowFromCorporateNetwork",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::your-bucket/*",
      "Condition": {
        "IpAddress": {
          "aws:SourceIp": "203.0.113.0/24"
        }
      }
    }
  ]
}
```

**Example: Time-Based Access**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "BusinessHoursOnly",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": "arn:aws:s3:::your-bucket/*",
      "Condition": {
        "DateLessThan": {
          "aws:CurrentTime": "2024-12-31T23:59:59Z"
        }
      }
    }
  ]
}
```

**Use Cases:**
- IP whitelisting/blacklisting
- Geographic restrictions
- Time-based access
- Custom authentication flows

---

## 🎯 Decision Matrix

| Requirement | Recommended Policy |
|------------|-------------------|
| Public website | `read_only` |
| CDN (CloudFront) | `cloudfront_oac` |
| Internal VPC only | `vpc_endpoint` |
| Multi-account access | `specific_accounts` |
| Enforce HTTPS | `require_ssl` |
| Complex rules | `custom` |
| Basic security | `require_ssl` (default) |

---

## 🔐 Security Recommendations

1. **Always use SSL enforcement** - Included by default in all policies (except custom)
2. **Enable versioning + MFA delete** - For critical data
3. **Block public access** - Unless specifically needed
4. **Use VPC endpoints** - For internal applications
5. **Log everything** - Enable access logging
6. **Least privilege** - Grant minimum required permissions

---

## 🧪 Testing Your Policy

```bash
# Test from allowed VPC
aws s3 ls s3://your-bucket --endpoint-url https://bucket.vpce-xxxxx.s3.us-east-1.vpce.amazonaws.com

# Test from denied location (should fail)
aws s3 ls s3://your-bucket

# Test with HTTP (should fail if SSL required)
curl http://your-bucket.s3.amazonaws.com/file.txt

# Test with HTTPS (should work)
curl https://your-bucket.s3.amazonaws.com/file.txt
```

---

## 📚 Additional Resources

- [AWS S3 Bucket Policy Examples](https://docs.aws.amazon.com/AmazonS3/latest/userguide/example-bucket-policies.html)
- [IAM Policy Elements](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_elements.html)
- [VPC Endpoints for S3](https://docs.aws.amazon.com/vpc/latest/privatelink/vpc-endpoints-s3.html)
- [CloudFront OAC Documentation](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/private-content-restricting-access-to-s3.html)
