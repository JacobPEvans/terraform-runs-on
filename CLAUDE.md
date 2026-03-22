# Terraform RunsOn - AI Agent Instructions

Self-hosted GitHub Actions runners on AWS EC2 spot instances via RunsOn.

## Technology Stack

- **Terraform + Terragrunt** - Infrastructure provisioning
- **GitHub Actions** - CI/CD (OIDC for AWS auth)
- **RunsOn** - Self-hosted runner orchestration
- **nix-devenv** - Dev shell via `shells/terraform` (includes aws-vault, awscli2, sops, tfsec, trivy)
- **aws-vault** - AWS credential management (macOS Keychain backend)

## Dev Environment

Uses [nix-devenv](https://github.com/JacobPEvans/nix-devenv) terraform shell via direnv.
No local `flake.nix` — the remote shell provides all tooling with per-shell lock isolation.

```bash
cd ~/git/terraform-runs-on/main
direnv allow    # one-time per worktree, then automatic
```

## Running Terraform Commands

```bash
aws-vault exec terraform --no-session -- terragrunt plan
aws-vault exec terraform --no-session -- terragrunt apply
```

## Architecture

- **VPC**: Dedicated VPC with 3 public subnets (us-east-2), no NAT Gateway
- **RunsOn**: Terraform module `runs-on/runs-on/aws` deploys App Runner + EC2 spot
- **OIDC**: GitHub Actions authenticates via OIDC (no stored AWS credentials in CI)
- **State**: S3 + DynamoDB via Terragrunt
- **Budget**: AWS Budget alarm at $10/month
- **Observability**: OTEL to Cribl.Cloud Free tier

## Secrets

| Secret | Source | Used By |
| ------ | ------ | ------- |
| `RUNSON_LICENSE` | Doppler | `TF_VAR_license_key` in CI |
| `AWS_OIDC_ROLE_ARN` | Terraform output | CI OIDC auth |
| AWS credentials | aws-vault profile `terraform` | Local operations only |

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
