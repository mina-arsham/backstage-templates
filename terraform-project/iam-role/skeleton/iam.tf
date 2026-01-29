resource "aws_iam_role" "main" {
  name = "${{ values.project_name }}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${{ values.aws_account_id }}:root"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Project   = "${{ values.project_name }}"
    ManagedBy = "backstage"
  }
}
