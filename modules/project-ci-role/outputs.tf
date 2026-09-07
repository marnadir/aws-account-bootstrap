output "role_arn" {
  description = "ARN del ruolo CI: va nell'env AWS_ROLE_ARN dei workflow del progetto"
  value       = aws_iam_role.github_ci.arn
}

output "role_name" {
  value = aws_iam_role.github_ci.name
}
