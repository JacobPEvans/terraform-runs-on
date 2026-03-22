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
      "arn:aws:s3:::terraform-runs-on-state-*",
      "arn:aws:s3:::terraform-runs-on-state-*/*",
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
    resources = ["arn:aws:dynamodb:*:${data.aws_caller_identity.current.account_id}:table/terraform-runs-on-locks-*"]
  }

  # RunsOn CloudFormation stacks
  statement {
    effect    = "Allow"
    actions   = ["cloudformation:*"]
    resources = ["arn:aws:cloudformation:*:${data.aws_caller_identity.current.account_id}:stack/runs-on*/*"]
  }

  # EC2/VPC for RunsOn infrastructure
  statement {
    effect = "Allow"
    actions = [
      "ec2:*",
      "apprunner:*",
      "sqs:*",
      "dynamodb:*",
      "iam:*",
      "logs:*",
      "s3:*",
      "cloudwatch:*",
      "budgets:*",
      "sns:*",
      "sts:GetCallerIdentity",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "github_actions" {
  name   = "terraform-runs-on-permissions"
  role   = aws_iam_role.github_actions.name
  policy = data.aws_iam_policy_document.github_actions_permissions.json
}
