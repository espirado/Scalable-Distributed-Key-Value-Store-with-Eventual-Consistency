terraform {
  backend "s3" {
    bucket         = "key-store-bucket-prkube"
    key            = "global/s3/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-lock-table"
    encrypt        = true
  }
}
