output "github_actions_role_arn" {
  description = "IAM role ARN for GitHub Actions OIDC authentication"
  value       = aws_iam_role.github_actions.arn
}

output "budget_name" {
  description = "Name of the AWS Budget"
  value       = aws_budgets_budget.runs_on.name
}
