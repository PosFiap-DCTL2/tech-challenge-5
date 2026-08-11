resource "aws_ecr_repository" "ngo-service" {
  name                 = "ngo-service"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }
}