# ECR Repositories for {{ values.teamName }} - {{ values.serviceName }}
# Generated: {{ values.timestamp }}
# Description: {{ values.description }}

#########################################################################
## releases {{ values.serviceName }} (prod/test environments)
#########################################################################
resource "aws_ecr_repository" "releases_{{ values.serviceName | replace('-', '_') }}" {
  name = "releases/{{ values.serviceName }}"

  encryption_configuration {
    encryption_type = "AES256"
  }

  image_scanning_configuration {
    scan_on_push = "{{ values.scanOnPush | default('true') }}"
  }

  image_tag_mutability = "{{ values.defaultMutability | default('IMMUTABLE') }}"

  tags = {
    Team        = "{{ values.teamName }}"
    Env         = "prod"
    Project     = "{{ values.project | default('fxb') }}"
    LegalEntity = "{{ values.legalEntity | default('abcd Group GmbH') }}"
    Terraform   = "true"
  }
}

resource "aws_ecr_repository_policy" "releases_{{ values.serviceName | replace('-', '_') }}_policy" {
  repository = aws_ecr_repository.releases_{{ values.serviceName | replace('-', '_') }}.name

  policy = <<POLICY
{
  "Statement": [
    {
      "Action": [
        "ecr:BatchCheckLayerAvailability",
        "ecr:BatchGetImage",
        "ecr:CompleteLayerUpload",
        "ecr:DescribeImages",
        "ecr:DescribeRepositories",
        "ecr:GetDownloadUrlForLayer",
        "ecr:GetLifecyclePolicyPreview",
        "ecr:GetRepositoryPolicy",
        "ecr:InitiateLayerUpload",
        "ecr:ListImages",
        "ecr:PutImage",
        "ecr:UploadLayerPart"
      ],
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "arn:aws:iam::1234566779:root",
          "arn:aws:iam::9242912345:root",
          "arn:aws:iam::7123456799:root",
          "arn:aws:iam::4341235699:root",
          "arn:aws:iam::7712345699:root"
        ]
      },
      "Sid": "RepoPolicy-ReadWrite"
    }
  ],
  "Version": "2008-10-17"
}
POLICY
}

resource "aws_ecr_lifecycle_policy" "releases_{{ values.serviceName | replace('-', '_') }}_lifecycle_policy" {
  repository = aws_ecr_repository.releases_{{ values.serviceName | replace('-', '_') }}.name
  depends_on = [aws_ecr_repository.releases_{{ values.serviceName | replace('-', '_') }}]
  policy     = <<EOF
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Image count more than {{ values.releasesImageCount | default('5') }}",
            "selection": {
                "tagStatus": "any",
                "countType": "imageCountMoreThan",
                "countNumber": {{ values.releasesImageCount | default('5') }}
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF
}


#########################################################################
## Snapshots {{ values.serviceName }} (dev/int environments)
#########################################################################
resource "aws_ecr_repository" "snapshots_{{ values.serviceName | replace('-', '_') }}" {
  name = "snapshots/{{ values.serviceName }}"

  encryption_configuration {
    encryption_type = "AES256"
  }

  image_scanning_configuration {
    scan_on_push = "{{ values.scanOnPush | default('true') }}"
  }

  image_tag_mutability = "{{ values.defaultMutability | default('IMMUTABLE') }}"

  tags = {
    Team        = "{{ values.teamName }}"
    Env         = "dev"
    Project     = "{{ values.project | default('fxb') }}"
    LegalEntity = "{{ values.legalEntity | default('abcd Group GmbH') }}"
    Terraform   = "true"
  }
}

resource "aws_ecr_repository_policy" "snapshots_{{ values.serviceName | replace('-', '_') }}_policy" {
  repository = aws_ecr_repository.snapshots_{{ values.serviceName | replace('-', '_') }}.name

  policy = <<POLICY
{
  "Statement": [
    {
      "Action": [
        "ecr:BatchCheckLayerAvailability",
        "ecr:BatchGetImage",
        "ecr:CompleteLayerUpload",
        "ecr:DescribeImages",
        "ecr:DescribeRepositories",
        "ecr:GetDownloadUrlForLayer",
        "ecr:GetLifecyclePolicyPreview",
        "ecr:GetRepositoryPolicy",
        "ecr:InitiateLayerUpload",
        "ecr:ListImages",
        "ecr:PutImage",
        "ecr:UploadLayerPart"
      ],
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "arn:aws:iam::1234566779:root",
          "arn:aws:iam::9242912345:root",
          "arn:aws:iam::7123456799:root",
          "arn:aws:iam::4341235699:root",
          "arn:aws:iam::7712345699:root"
        ]
      },
      "Sid": "RepoPolicy-ReadWrite"
    }
  ],
  "Version": "2008-10-17"
}
POLICY
}

resource "aws_ecr_lifecycle_policy" "snapshots_{{ values.serviceName | replace('-', '_') }}_lifecycle_policy" {
  repository = aws_ecr_repository.snapshots_{{ values.serviceName | replace('-', '_') }}.name
  depends_on = [aws_ecr_repository.snapshots_{{ values.serviceName | replace('-', '_') }}]
  policy     = <<EOF
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Image count more than {{ values.snapshotsImageCount | default('5') }}",
            "selection": {
                "tagStatus": "any",
                "countType": "imageCountMoreThan",
                "countNumber": {{ values.snapshotsImageCount | default('5') }}
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF
}
