# VPC Module

This module creates a complete Virtual Private Cloud (VPC) infrastructure with public and private subnets across multiple availability zones.

## Purpose

The VPC module provides network isolation and segmentation for your AWS resources, following AWS best practices for multi-AZ deployments.

## Resources Created

- **VPC**: The main virtual network
- **Public Subnets**: Subnets with internet access via Internet Gateway
- **Private Subnets**: Subnets without direct internet access
- **Internet Gateway**: Provides internet connectivity for public subnets
- **Route Tables**: Separate routing for public and private subnets
- **Route Table Associations**: Links subnets to their respective route tables

## Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `vpc_name` | string | required | Name tag for the VPC |
| `vpc_cidr` | string | `10.0.0.0/16` | CIDR block for the VPC |
| `public_subnet_cidrs` | list(string) | `[]` | List of CIDR blocks for public subnets |
| `private_subnet_cidrs` | list(string) | `[]` | List of CIDR blocks for private subnets |
| `availability_zones` | list(string) | required | List of AZs to deploy subnets in |
| `enable_dns_hostnames` | bool | `true` | Enable DNS hostnames in the VPC |
| `enable_dns_support` | bool | `true` | Enable DNS resolution in the VPC |
| `tags` | map(string) | `{}` | Additional tags for all resources |

## Outputs

| Output | Description |
|--------|-------------|
| `vpc_id` | The ID of the VPC |
| `vpc_cidr` | The CIDR block of the VPC |
| `public_subnet_ids` | List of public subnet IDs |
| `private_subnet_ids` | List of private subnet IDs |
| `internet_gateway_id` | ID of the internet gateway |
| `public_route_table_id` | ID of the public route table |
| `private_route_table_id` | ID of the private route table |

## Usage Example

```hcl
module "vpc" {
  source = "./modules/vpc"

  vpc_name             = "production-vpc"
  vpc_cidr             = "10.0.0.0/16"
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]
  availability_zones   = ["us-east-1a", "us-east-1b"]

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

## Best Practices

1. **CIDR Planning**: Use non-overlapping CIDR blocks with sufficient IP space
2. **Multi-AZ**: Deploy across at least 2 availability zones for high availability
3. **Subnet Sizing**: Leave room for growth (e.g., /24 gives 256 IPs per subnet)
4. **Private Subnets**: Use for databases and backend services that don't need internet access
5. **DNS Settings**: Keep DNS hostnames enabled for easier resource management
