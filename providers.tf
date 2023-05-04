terraform {
  backend "s3" {
    bucket = "k8s.tf.bucket"
    region = "us-east-2"
    key    = "ec2_terraform.tfstate"
    dynamodb_table = "my-terraform-state-lock-table_2"
    encrypt = true
  }

  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 4.47.0"
    }
  }
}

provider "aws" {
  region	= var.AWS_REGION
}
