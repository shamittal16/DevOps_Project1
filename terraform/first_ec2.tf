provider "aws" {
  region     = "ap-southeast-2"
  access_key = "AKIAZ46F6WUDJ7OTOUVG"
  secret_key = "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"
}

resource "aws_instance" "first-aws-ec2" {
  ami           = "ami-0b3c832b6b7289e44"
  instance_type = "t3.micro"

  tags = {
    Name ="first-ec2-instance"
  }
}
