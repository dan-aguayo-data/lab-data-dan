terraform {
    backend "s3" {
        bucket = "my-terraform-state-bucket-daniel"
        key    = "my-first-backend/terraform.tfstate" #s3 bucket path
        region = "ap-southeast-2"
        dynamodb_table = "terraform-locks"
    }
}
