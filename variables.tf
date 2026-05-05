variable "aws_region" {
  description = "Primary AWS region for all resources."
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment tag (prod, staging, dev)."
  type        = string
  default     = "prod"

  validation {
    condition     = contains(["prod", "staging", "dev"], var.environment)
    error_message = "environment must be one of: prod, staging, dev."
  }
}

variable "hub_vpc_cidr" {
  description = "CIDR block for the hub (shared-services) VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "spokes" {
  description = "List of spoke VPC definitions."
  type = list(object({
    name     = string
    vpc_cidr = string
  }))
  default = [
    { name = "app", vpc_cidr = "10.1.0.0/16" },
    { name = "data", vpc_cidr = "10.2.0.0/16" },
  ]
}

variable "availability_zones" {
  description = "Availability zones to deploy subnets into (min 2)."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs for all VPCs."
  type        = bool
  default     = true
}

variable "flow_logs_retention_days" {
  description = "CloudWatch log retention in days for VPC Flow Logs."
  type        = number
  default     = 30
}

variable "enable_config_recorder" {
  description = "Enable AWS Config recorder and compliance rules."
  type        = bool
  default     = true
}

variable "alert_email" {
  description = "Email address to receive SNS compliance alerts."
  type        = string
  default     = ""
}
