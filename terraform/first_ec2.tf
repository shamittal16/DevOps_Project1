provider "aws" {
  region     = "us-east-1"
}

resource "aws_instance" "first-aws-ec2" {
  ami           = "ami-068c0051b15cdb816"
  instance_type = "t3.micro"

  tags = {
    Name = "instance-1"
  }
}

resource "aws_security_group" "tf-sg" {
  name = "terraform-firewall-sg"
  description = "Security group managed by tf"

  tags = {
    Name = "terraform-firewall-sg"  
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow-http-ingress" {
  security_group_id = aws_security_group.tf-sg.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 80
  ip_protocol = "tcp"
  to_port     = 80
}

resource "aws_vpc_security_group_egress_rule" "allow-all" {
  security_group_id = aws_security_group.tf-sg.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"
}