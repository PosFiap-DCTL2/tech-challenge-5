resource "aws_ecr_repository" "volunteer-service" {
  name                 = "tech5/volunteer-service"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }
}