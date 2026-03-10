terraform {
  backend "s3" {
    bucket         = "eft-data-terraform-backend"
    key            = "mssql_bcp_export/DW/terraform.tfstate"
    region         = "ap-southeast-2"
    encrypt        = true
    dynamodb_table = "terraform-state-lock-data-export-dw"
  }
}
