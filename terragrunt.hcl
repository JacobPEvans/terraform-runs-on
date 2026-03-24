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
    bucket         = "${get_aws_account_id()}-${local.aws_region_compact}-tfstate-terraform-runs-on"
    key            = "terraform-runs-on/terraform.tfstate"
    region         = local.aws_region
    encrypt        = true
    use_lockfile   = true
    dynamodb_table = "${local.aws_region_compact}-tflocks-terraform-runs-on"
    max_retries    = 5
  }
}

inputs = {
  aws_region  = local.aws_region
  license_key = get_env("RUNSON_LICENSE_KEY", "")
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
