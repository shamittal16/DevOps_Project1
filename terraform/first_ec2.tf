provider "aws" {
  region     = "ap-southeast-2"
  access_key = "AKIAZ46F6WUDG5FX7AYC"
  secret_key = "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"
}

resource "aws_instance" "first-aws-ec2" {
  ami           = "ami-0b3c832b6b7289e44"
  instance_type = "t3.micro"

  tags = {
    Name ="my-first-aws-ec2"
  }
}