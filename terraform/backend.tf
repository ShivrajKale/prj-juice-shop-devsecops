terraform {
  backend "s3" {
    bucket = "prj-juice-shop-tfstate"
    key    = "prj-juice-shop/terraform.tfstate"
    region = "us-east-1"
    dynamodb_table = "juice-shop-tflock"
    encrypt = true 
  }
}