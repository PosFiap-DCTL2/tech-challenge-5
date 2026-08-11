resource "aws_dynamodb_table" "SolidaryTechVolunteers" {
  name           = "SolidaryTechVolunteers"
  billing_mode   = "PROVISIONED"
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "volunteer_id"

  attribute {
    name = "volunteer_id"
    type = "S"
  }
}