terraform {
  backend "s3" {
    bucket         = "tfstate-artifactory"
    key            = "ec2/main/terraform.tfstate"
    region         = "ap-southeast-2"
    dynamodb_table = "terraform-lock"
    encrypt        = true
  }
}