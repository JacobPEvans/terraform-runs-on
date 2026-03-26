# terraform-runs-on

Self-hosted GitHub Actions runners on AWS EC2 spot instances via [RunsOn](https://runs-on.com).

## What This Does

Deploys RunsOn infrastructure to AWS, providing self-hosted GitHub Actions runners that are:

- **10x cheaper** than GitHub-hosted runners (EC2 spot instances)
- **2x faster** (dedicated compute, no queue wait)
- **Auto-scaling** (runners spin up on demand, terminate when done)

## Architecture

```text
GitHub Actions Workflow
        |
        v
RunsOn App Runner (orchestrator, ~$3/month)
        |
        v
EC2 Spot Instances (runners, ~$0.03/hr)
  - 3 AZs in us-east-2
  - Spot circuit breaker (auto-fallback to on-demand)
  - Cost allocation tags per workflow/job/repo
        |
        v
Cribl.Cloud Free (observability, $0/month)
  - OTLP telemetry
  - Forward to Splunk/S3
```

## Cost

| Component | Monthly |
| --------- | ------- |
| App Runner | ~$3 |
| EC2 spot | ~$1-4 |
| CloudWatch (30d) | ~$0.50 |
| **Total** | **~$5-8** |

Budget alarm at $10/month with alerts at 50%, 80%, 100%.

## Usage

After deployment, use RunsOn runners in any workflow:

```yaml
jobs:
  build:
    runs-on: runs-on,runner=2cpu-linux-x64,family=c7+m7
    steps:
      - uses: actions/checkout@v4
      - run: echo "Running on RunsOn!"
```

## Installation

### Prerequisites

- [Nix](https://nixos.org/download) with flakes enabled
- [direnv](https://direnv.net/)
- [aws-vault](https://github.com/99designs/aws-vault) with a `tf-runs-on` profile
- A [RunsOn](https://runs-on.com) license key

### Setup

```bash
# Clone with bare repo + worktree convention
cd ~/git
git clone --bare https://github.com/JacobPEvans/terraform-runs-on.git terraform-runs-on/.git
cd terraform-runs-on
git worktree add main main

# Activate dev shell
cd main
direnv allow

# Bootstrap infrastructure
aws-vault exec tf-runs-on -- doppler run -- terragrunt init
aws-vault exec tf-runs-on -- doppler run -- terragrunt apply
```

## Development

```bash
direnv allow                                                        # Activate Nix shell
aws-vault exec tf-runs-on -- doppler run -- terragrunt plan         # Preview changes
aws-vault exec tf-runs-on -- doppler run -- terragrunt apply        # Apply changes
```

## CI/CD

- **PR**: Automatic `terraform validate` + `terragrunt plan` (posted as PR comment)
- **Merge to main**: Automatic `terragrunt apply` via OIDC (requires `production` environment approval)
- **Releases**: Automated via Release Please

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
