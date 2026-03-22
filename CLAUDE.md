# Terraform RunsOn - AI Agent Instructions

Self-hosted GitHub Actions runners on AWS EC2 spot instances via RunsOn.

## Technology Stack

- **Terraform + Terragrunt** - Infrastructure provisioning
- **GitHub Actions** - CI/CD (OIDC for AWS auth)
- **RunsOn** - Self-hosted runner orchestration
- **Nix Shell** - Provides Terraform/Terragrunt tooling
- **aws-vault** - AWS credentials for local bootstrapping

## Running Terraform Commands

```bash
aws-vault exec terraform --no-session -- terragrunt plan
aws-vault exec terraform --no-session -- terragrunt apply
```

The Nix shell is activated automatically via direnv.

## Architecture

- **VPC**: Dedicated VPC with 3 public subnets (us-east-2), no NAT Gateway
- **RunsOn**: Terraform module `runs-on/runs-on/aws` deploys App Runner + EC2 spot
- **OIDC**: GitHub Actions authenticates via OIDC (no stored AWS credentials in CI)
- **State**: S3 + DynamoDB via Terragrunt
- **Budget**: AWS Budget alarm at $10/month
- **Observability**: OTEL to Cribl.Cloud Free tier

## Secrets

| Secret | Source | Used By |
|--------|--------|---------|
| `RUNSON_LICENSE` | Doppler | `TF_VAR_license_key` in CI |
| `AWS_OIDC_ROLE_ARN` | Terraform output | CI OIDC auth |
| AWS credentials | aws-vault profile `terraform` | Local bootstrapping only |

## Cost Target

~$5-8/month: App Runner (~$3) + EC2 spot (~$1-4) + CloudWatch ($0.50).
Budget alarm alerts at 50%, 80%, 100% of $10/month.

## Worktree Structure

```text
~/git/terraform-runs-on/
  .git/     # Bare repo
  main/     # Main branch worktree
  feat/     # Feature worktrees
```
