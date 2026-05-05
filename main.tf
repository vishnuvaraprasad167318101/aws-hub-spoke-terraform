terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # backend "s3" {
  #   bucket = "your-terraform-state-bucket"
  #   key    = "hub-spoke/terraform.tfstate"
  #   region = "us-east-1"
  # }
  # Uncomment the s3 backend above and run: terraform init -backend-config=backend.tfvars
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "hub-spoke-network"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

# ---------------------------------------------------------------------------
# Hub VPC
# ---------------------------------------------------------------------------
module "hub_vpc" {
  source = "./modules/hub-vpc"

  vpc_cidr            = var.hub_vpc_cidr
  environment         = var.environment
  availability_zones  = var.availability_zones
  enable_flow_logs    = var.enable_flow_logs
  flow_logs_retention = var.flow_logs_retention_days
}

# ---------------------------------------------------------------------------
# Transit Gateway
# ---------------------------------------------------------------------------
module "transit_gateway" {
  source = "./modules/transit-gateway"

  environment        = var.environment
  hub_vpc_id         = module.hub_vpc.vpc_id
  hub_route_table_id = module.hub_vpc.private_route_table_id
  hub_subnet_ids     = module.hub_vpc.private_subnet_ids
  spoke_cidrs        = [for s in var.spokes : s.vpc_cidr]
}

# ---------------------------------------------------------------------------
# Spoke VPCs — one per entry in var.spokes
# ---------------------------------------------------------------------------
module "spoke_vpcs" {
  source   = "./modules/spoke-vpc"
  for_each = { for s in var.spokes : s.name => s }

  name                = each.value.name
  vpc_cidr            = each.value.vpc_cidr
  environment         = var.environment
  availability_zones  = var.availability_zones
  enable_flow_logs    = var.enable_flow_logs
  flow_logs_retention = var.flow_logs_retention_days

  transit_gateway_id     = module.transit_gateway.tgw_id
  hub_cidr               = var.hub_vpc_cidr
  additional_route_cidrs = [for s in var.spokes : s.vpc_cidr if s.name != each.value.name]
}

# Attach each spoke to the Transit Gateway
resource "aws_ec2_transit_gateway_vpc_attachment" "spoke" {
  for_each = module.spoke_vpcs

  transit_gateway_id = module.transit_gateway.tgw_id
  vpc_id             = each.value.vpc_id
  subnet_ids         = each.value.private_subnet_ids

  tags = {
    Name = "tgw-attach-${each.key}"
  }
}

# ---------------------------------------------------------------------------
# Compliance & Config Rules
# ---------------------------------------------------------------------------
module "compliance" {
  source = "./modules/compliance"

  environment            = var.environment
  spoke_vpc_ids          = [for s in module.spoke_vpcs : s.vpc_id]
  hub_vpc_id             = module.hub_vpc.vpc_id
  alert_email            = var.alert_email
  enable_config_recorder = var.enable_config_recorder
}
