# Terraform RunsOn - AI Agent Instructions

Self-hosted GitHub Actions runners on AWS EC2 spot instances via RunsOn.

## Technology Stack

- **Terraform/Terragrunt** - Infrastructure provisioning
- **GitHub Actions** - CI/CD (OIDC for AWS auth)
- **RunsOn** - Self-hosted runner orchestration
- **nix-devenv** - Dev shell via `shells/terraform` (includes aws-vault, awscli2, sops, tfsec, trivy)
- **aws-vault** - AWS credentials for S3 backend (profile: `terraform`)
- **Doppler** - Runtime secrets (RunsOn license key)

## Running Terraform Commands

**CRITICAL**: All Terragrunt commands require the complete toolchain wrapper.

### The Command (always this, always both)

```bash
aws-vault exec terraform -- doppler run -- terragrunt <COMMAND>
```

### Command Breakdown

1. **`aws-vault exec terraform`** - AWS credentials for S3 backend (profile: `terraform`)
2. **`doppler run --`** - Injects secrets as env vars (`RUNSON_LICENSE` as `TF_VAR_license_key`)
3. **`terragrunt <COMMAND>`** - Runs Terraform

### Common Commands

```bash
aws-vault exec terraform -- doppler run -- terragrunt validate
aws-vault exec terraform -- doppler run -- terragrunt plan
aws-vault exec terraform -- doppler run -- terragrunt apply
```

### Claude Code Sessions

Start Claude inside aws-vault to get 1hr credential access without per-command popups:

```bash
cd ~/git/terraform-runs-on/main
aws-vault exec terraform -- claude
```

Then terragrunt commands only need Doppler (AWS credentials are inherited):

```bash
doppler run -- terragrunt plan
doppler run -- terragrunt apply
```

### Doppler Configuration

Doppler must be configured once per repo root (inherited by all worktrees):

```bash
doppler setup --project <PROJECT> --config <CONFIG>
```

This creates a local `.doppler.yaml` (gitignored).

## Dev Environment

Uses [nix-devenv](https://github.com/JacobPEvans/nix-devenv) terraform shell via direnv.
No local `flake.nix` — the remote shell provides all tooling with per-shell lock isolation.

```bash
direnv allow    # one-time per worktree, then automatic
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
| `RUNSON_LICENSE` | Doppler | `TF_VAR_license_key` via `doppler run` |
| `AWS_OIDC_ROLE_ARN` | Terraform output | CI OIDC auth |
| AWS credentials | aws-vault profile `terraform` | S3 backend auth |

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
