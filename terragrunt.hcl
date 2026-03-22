locals {
  aws_region         = "us-east-2"
  aws_region_compact = replace(local.aws_region, "-", "")
}

terraform {
  source = "."
}

remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket         = "terraform-runs-on-state-${local.aws_region_compact}-${get_aws_account_id()}"
    key            = "terraform-runs-on/terraform.tfstate"
    region         = local.aws_region
    encrypt        = true
    use_lockfile   = true
    dynamodb_table = "terraform-runs-on-locks-${local.aws_region_compact}"
    max_retries    = 5
  }
}

inputs = {
  aws_region = local.aws_region
}

generate "provider" {
  path      = "provider_override.tf"
  if_exists = "overwrite"
  contents  = <<EOF
provider "aws" {
  region = "${local.aws_region}"

  default_tags {
    tags = {
      Project     = "terraform-runs-on"
      ManagedBy   = "terraform"
      Environment = "production"
    }
  }
}
EOF
}
