---
description: Terraform/Terragrunt command execution rules for this repository
globs:
  - "*.tf"
  - "*.hcl"
  - "terragrunt.hcl"
---

# Terraform Command Rules

## Required Command Chain

All terragrunt commands MUST use the full toolchain:

```bash
aws-vault exec terraform -- doppler run -- terragrunt <COMMAND>
```

## Never Do

- Never run `terragrunt` without `aws-vault` and `doppler` wrapping it
- Never use `--no-session` flag with aws-vault
- Never guess aws-vault profile names — the profile is always `terraform`
- Never use `--name-transformer` with doppler (that is terraform-proxmox specific)
- Never use raw `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` env vars
- Never create S3 buckets or DynamoDB tables manually — terragrunt `--backend-bootstrap` does this

## Claude Code Sessions

When running inside `aws-vault exec terraform -- claude`, AWS credentials are already
in the environment. Commands only need Doppler:

```bash
doppler run -- terragrunt plan
doppler run -- terragrunt apply
```

Check for inherited credentials: if `AWS_VAULT` env var is set, skip the aws-vault wrapper.

## Doppler Setup

Doppler must be configured before any terragrunt command will work:

```bash
doppler setup --project <PROJECT> --config <CONFIG>
```

If `doppler run` fails with "no config", Doppler setup has not been run in this worktree.
