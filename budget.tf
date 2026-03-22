resource "aws_budgets_budget" "runs_on" {
  name         = "runs-on-runners"
  budget_type  = "COST"
  limit_amount = tostring(var.monthly_budget_usd)
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  cost_filter {
    name = "Service"
    values = [
      "Amazon Elastic Compute Cloud - Compute",
      "AWS App Runner",
      "Amazon Simple Storage Service",
      "AmazonCloudWatch",
    ]
  }

  dynamic "notification" {
    for_each = [50, 80, 100]
    content {
      comparison_operator        = "GREATER_THAN"
      threshold                  = notification.value
      threshold_type             = "PERCENTAGE"
      notification_type          = "ACTUAL"
      subscriber_email_addresses = [var.email]
    }
  }

  tags = local.common_tags
}
