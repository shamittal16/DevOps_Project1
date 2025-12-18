provider "aws" {
  region     = var.aws_region
}

resource "aws_instance" "first-aws-ec2" {
  ami           = "ami-0b3c832b6b7289e44"
  instance_type = "t3.micro"

  tags = {
    Name ="first-ec2-instance"
  }
}
