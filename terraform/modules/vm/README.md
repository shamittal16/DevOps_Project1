# VM (EC2 Instance) Module

This module creates an EC2 instance with an associated security group, supporting common configurations like IAM roles, user data scripts, and customizable ingress/egress rules.

## Purpose

Provides a reusable way to deploy EC2 instances with security groups, following the principle of least privilege and infrastructure as code best practices.

## Resources Created

- **EC2 Instance**: Virtual machine with specified configuration
- **Security Group**: Network firewall rules for the instance
- **Ingress Rules**: Inbound traffic rules
- **Egress Rules**: Outbound traffic rules

## Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `instance_name` | string | required | Name tag for the instance |
| `ami` | string | required | AMI ID to use for the instance |
| `instance_type` | string | `t3.micro` | EC2 instance type |
| `subnet_id` | string | required | Subnet ID to launch the instance in |
| `vpc_id` | string | required | VPC ID for the security group |
| `key_name` | string | `null` | SSH key pair name |
| `iam_instance_profile` | string | `null` | IAM instance profile name |
| `root_volume_size` | number | `8` | Size of root volume in GB |
| `root_volume_type` | string | `gp3` | Type of root volume (gp3, gp2, io1) |
| `delete_on_termination` | bool | `true` | Delete volume when instance terminates |
| `encrypt_root_volume` | bool | `true` | Encrypt the root volume |
| `user_data` | string | `null` | User data script for initialization |
| `associate_public_ip_address` | bool | `false` | Associate public IP address |
| `security_group_name` | string | required | Name for the security group |
| `security_group_description` | string | `"Security group managed by Terraform"` | Description for the security group |
| `ingress_rules` | list(object) | `[]` | List of ingress rules |
| `egress_rules` | list(object) | `[]` | List of egress rules |
| `tags` | map(string) | `{}` | Tags for all resources |

### Ingress/Egress Rule Structure

```hcl
ingress_rules = [
  {
    cidr_ipv4   = "10.0.0.0/16"
    from_port   = 80
    to_port     = 80
    ip_protocol = "tcp"
    description = "Allow HTTP from VPC"  # optional
  }
]
```

## Outputs

| Output | Description |
|--------|-------------|
| `instance_id` | ID of the EC2 instance |
| `instance_public_ip` | Public IP address |
| `instance_private_ip` | Private IP address |
| `security_group_id` | ID of the security group |
| `instance_arn` | ARN of the instance |

## Usage Example

```hcl
module "web_server" {
  source = "./modules/vm"

  instance_name           = "web-server-01"
  ami                     = "ami-0c55b159cbfafe1f0"
  instance_type           = "t3.small"
  subnet_id               = module.vpc.public_subnet_ids[0]
  vpc_id                  = module.vpc.vpc_id
  iam_instance_profile    = "my-instance-profile"
  security_group_name     = "web-server-sg"
  
  ingress_rules = [
    {
      cidr_ipv4   = "0.0.0.0/0"
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      description = "HTTPS from internet"
    }
  ]
  
  egress_rules = [
    {
      cidr_ipv4   = "0.0.0.0/0"
      ip_protocol = "-1"
      description = "All outbound"
    }
  ]

  tags = {
    Environment = "production"
  }
}
```

## Best Practices

1. **Encryption**: Always encrypt root volumes (enabled by default)
2. **Volume Type**: Use gp3 for better performance and cost vs gp2
3. **Security Groups**: Apply principle of least privilege - only open required ports
4. **IAM Roles**: Use IAM instance profiles instead of embedding credentials
5. **User Data**: Keep initialization scripts idempotent
6. **Public IPs**: Only use for resources that need direct internet access
