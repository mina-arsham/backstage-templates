output "iam_role_name" {
  value = aws_iam_role.{{ project_name }}.name
}
