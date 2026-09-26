terraform {
  backend "s3" {
    bucket = "bucketguardastateterraform4"
    key    = "terraform.tfstate"
    region = "us-east-1"

    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
