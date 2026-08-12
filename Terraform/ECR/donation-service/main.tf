resource "aws_ecr_repository" "donation-service" {
  name                 = "tech5/donation-service"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }
}