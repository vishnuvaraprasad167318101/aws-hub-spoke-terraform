# AWS Hub-Spoke Network Architecture with Automated Compliance

Production-ready Terraform infrastructure implementing a hub-and-spoke VPC topology using AWS Transit Gateway, with automated compliance enforcement via AWS Config, event-driven Lambda remediation, and a full GitHub Actions CI/CD pipeline.

## Architecture

```
                    ┌──────────────────────────────┐
                    │        Hub VPC (10.0.0.0/16)  │
                    │  ┌─────────┐  ┌────────────┐  │
                    │  │ Public  │  │  Private   │  │
                    │  │Subnets  │  │  Subnets   │  │
                    │  └────┬────┘  └─────┬──────┘  │
                    │  NAT GW│            │TGW attach│
                    └────────┼────────────┼──────────┘
                             │            │
                    ┌────────▼────────────▼──────────┐
                    │      Transit Gateway            │
                    │  Hub RT ←→ Spoke RT             │
                    └────┬───────────┬───────────┬───┘
               ┌─────────▼──┐  ┌────▼────┐  ┌───▼──────┐
               │  App VPC   │  │Data VPC │  │Security  │
               │10.1.0.0/16 │  │10.2.0/16│  │10.3.0/16 │
               └────────────┘  └─────────┘  └──────────┘
```

**AWS Config → Lambda → Auto-Remediation → SNS Alert**

## Features

- **Transit Gateway routing** with separate route tables for hub vs. spokes (no spoke-to-spoke lateral movement by default)
- **VPC Flow Logs** enabled on all VPCs → CloudWatch Logs
- **AWS Config** managed rules: SSH disabled, RDP restricted, S3 public access prohibited, VPC flow logs enabled
- **Lambda auto-remediation**: detects Config violations and auto-revokes open SSH/RDP rules or enables flow logs
- **SNS alerts** on every compliance violation and remediation action
- **GitHub Actions CI/CD**: validate → plan (PR comment) → apply (merge to main), using OIDC IAM roles (no long-lived keys)
- All default Security Groups locked down (deny all)

## Prerequisites

- Terraform >= 1.5.0
- AWS CLI configured
- S3 bucket for Terraform remote state
- GitHub OIDC IAM role for CI/CD (no stored AWS keys)

## Setup

```bash
git clone https://github.com/YOUR_USERNAME/aws-hub-spoke-terraform
cd aws-hub-spoke-terraform

# Copy and edit vars
cp terraform.tfvars.example terraform.tfvars

# Configure backend
cat > backend.tfvars <<EOF
bucket = "your-terraform-state-bucket"
key    = "hub-spoke/terraform.tfstate"
region = "us-east-1"
EOF

terraform init -backend-config=backend.tfvars
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

## GitHub Actions Secrets Required

| Secret | Description |
|--------|-------------|
| `AWS_DEPLOY_ROLE_ARN` | IAM role ARN for OIDC (no long-lived keys) |
| `ALERT_EMAIL` | Email for SNS compliance alerts |

## Module Structure

```
modules/
├── hub-vpc/          VPC, subnets, NAT gateways, IGW, flow logs
├── transit-gateway/  TGW, route tables, hub attachment, spoke routes
├── spoke-vpc/        Spoke VPC, private subnets, TGW-bound routes, flow logs
└── compliance/       Config recorder, Config rules, Lambda remediation, SNS
lambda/
└── remediation/      Python Lambda: revokes open ports, enables flow logs
.github/workflows/
└── terraform.yml     validate → plan (PR) → apply (main)
```

## Technologies

Terraform · AWS VPC · Transit Gateway · AWS Config · Lambda (Python) · SNS · CloudWatch · GitHub Actions · OIDC IAM
