resource "aws_db_instance" "donationdb" {
  allocated_storage    = 10
  db_name              = "donationdb"
  engine               = "postgres"
  engine_version       = "15.4"
  instance_class       = var.instanceclass
  username             = var.user
  password             = var.password
  parameter_group_name = "default.postgres8.0"
  skip_final_snapshot  = true

  publicly_accessible    = true
  db_subnet_group_name   = var.network.subnet_group_id
  vpc_security_group_ids = [var.network.security_group_id]

  tags = {
    Name        = "SolidaryTech"
    Environment = "Production"
    CostCenter  = "Donation-Core"
  }
}
