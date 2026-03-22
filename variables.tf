variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-2"
}

variable "github_organization" {
  description = "GitHub organization or username"
  type        = string
  default     = "JacobPEvans"
}

variable "license_key" {
  description = "RunsOn license key"
  type        = string
  sensitive   = true
}

variable "email" {
  description = "Email for cost and alert reports"
  type        = string
  default     = "20714140+JacobPEvans@users.noreply.github.com"
}

variable "otel_exporter_endpoint" {
  description = "OpenTelemetry exporter endpoint (Cribl.Cloud OTLP URL)"
  type        = string
  default     = ""
}

variable "otel_exporter_headers" {
  description = "OpenTelemetry exporter headers (W3C Baggage format)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "monthly_budget_usd" {
  description = "Monthly budget limit in USD"
  type        = number
  default     = 10.0
}
