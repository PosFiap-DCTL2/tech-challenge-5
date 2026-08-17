resource "aws_ecr_repository" "ngo-service" {
  name                 = "tech5/ngo-service"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }

  tags = {
    Name        = "SolidaryTech"
    Environment = "Production"
    CostCenter  = "NGO-Core"
  }
}