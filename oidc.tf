# GitHub Actions OIDC Provider
# One-per-account resource. If another repo creates one later, import it:
#   terraform import aws_iam_openid_connect_provider.github <arn>
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["ffffffffffffffffffffffffffffffffffffffff"]

  tags = local.common_tags
}

# IAM Role for GitHub Actions OIDC authentication
data "aws_iam_policy_document" "github_actions_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:JacobPEvans/terraform-runs-on:*"]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name               = "terraform-runs-on-github-actions"
  assume_role_policy = data.aws_iam_policy_document.github_actions_trust.json

  tags = local.common_tags
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "github_actions_permissions" {
  # Terraform state bucket
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket",
      "s3:GetBucketLocation",
      "s3:GetBucketVersioning",
    ]
    resources = [
      "arn:aws:s3:::*-tfstate-terraform-runs-on",
      "arn:aws:s3:::*-tfstate-terraform-runs-on/*",
    ]
  }

  # Terraform state lock table
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem",
      "dynamodb:DescribeTable",
    ]
    resources = ["arn:aws:dynamodb:*:${data.aws_caller_identity.current.account_id}:table/*-tflocks-terraform-runs-on"]
  }

  # RunsOn CloudFormation stacks
  statement {
    effect    = "Allow"
    actions   = ["cloudformation:*"]
    resources = ["arn:aws:cloudformation:*:${data.aws_caller_identity.current.account_id}:stack/runs-on*/*"]
  }

  # EC2/VPC and App Runner — must remain * (AWS requires it for RunInstances, Describe*)
  statement {
    effect = "Allow"
    actions = [
      "ec2:*",
      "apprunner:*",
      "sts:GetCallerIdentity",
    ]
    resources = ["*"]
  }

  # IAM scoped to runs-on resources only
  statement {
    effect = "Allow"
    actions = [
      "iam:*",
    ]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/runs-on*",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:instance-profile/runs-on*",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/runs-on*",
    ]
  }

  # S3 scoped to runs-on module buckets (state bucket handled above)
  statement {
    effect = "Allow"
    actions = [
      "s3:*",
    ]
    resources = [
      "arn:aws:s3:::runs-on-*",
      "arn:aws:s3:::runs-on-*/*",
    ]
  }

  # DynamoDB scoped to runs-on module tables (state lock handled above)
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:*",
    ]
    resources = [
      "arn:aws:dynamodb:*:${data.aws_caller_identity.current.account_id}:table/runs-on-*",
    ]
  }

  # SQS scoped to runs-on queues
  statement {
    effect = "Allow"
    actions = [
      "sqs:*",
    ]
    resources = [
      "arn:aws:sqs:*:${data.aws_caller_identity.current.account_id}:runs-on-*",
    ]
  }

  # Logs, CloudWatch, Budgets, SNS — Describe/List actions require * resources
  statement {
    effect = "Allow"
    actions = [
      "logs:*",
      "cloudwatch:*",
      "budgets:*",
      "sns:*",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "github_actions" {
  name   = "terraform-runs-on-permissions"
  role   = aws_iam_role.github_actions.name
  policy = data.aws_iam_policy_document.github_actions_permissions.json
}
