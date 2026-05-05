output "hub_vpc_id" {
  description = "Hub VPC ID."
  value       = module.hub_vpc.vpc_id
}

output "hub_vpc_cidr" {
  description = "Hub VPC CIDR block."
  value       = module.hub_vpc.vpc_cidr
}

output "hub_public_subnet_ids" {
  description = "Hub public subnet IDs."
  value       = module.hub_vpc.public_subnet_ids
}

output "hub_private_subnet_ids" {
  description = "Hub private subnet IDs."
  value       = module.hub_vpc.private_subnet_ids
}

output "transit_gateway_id" {
  description = "Transit Gateway ID."
  value       = module.transit_gateway.tgw_id
}

output "transit_gateway_arn" {
  description = "Transit Gateway ARN."
  value       = module.transit_gateway.tgw_arn
}

output "spoke_vpc_ids" {
  description = "Map of spoke name → VPC ID."
  value       = { for k, v in module.spoke_vpcs : k => v.vpc_id }
}

output "spoke_private_subnet_ids" {
  description = "Map of spoke name → list of private subnet IDs."
  value       = { for k, v in module.spoke_vpcs : k => v.private_subnet_ids }
}

output "compliance_sns_topic_arn" {
  description = "SNS topic ARN for compliance alerts."
  value       = module.compliance.sns_topic_arn
}
