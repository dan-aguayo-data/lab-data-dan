terraform {
  backend "s3" {
    bucket         = "eft-data-terraform-backend"  # Update with your state bucket
    key            = "aws_mssql_ecs/terraform.tfstate"
    region         = "ap-southeast-2"
    encrypt        = true
    dynamodb_table = "terraform-state-lock-data-mssql"  # Update with your lock table
  }
}
