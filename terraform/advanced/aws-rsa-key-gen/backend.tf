terraform {
  backend "s3" {
    bucket         = "eft-data-terraform-backend"
    key            = "snowflake/skg-prod.tfstate"
    region         = "ap-southeast-2"
    encrypt        = true
    dynamodb_table = "terraform-state-lock-data-service-key-gen"
  }
}