# Backend config to store tfstate in an S3 bucket

terraform {
  backend "s3" {
    bucket  = "sctp-ce9-tfstate"
    key     = "LAC-ce9-coaching5Apr.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
  required_version = ">= 1.0.0"
}