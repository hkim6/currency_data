resource "aws_db_instance" "default" {
  allocated_storage    = 20
  db_name              = "currency_db"
  identifier           = "currency-pg-db"
  engine               = "postgres"
  instance_class       = "db.t3.micro"
  username             = var.db_username
  password             = var.db_password
  skip_final_snapshot  = true
  port               = 5432

  publicly_accessible = true
  vpc_security_group_ids = [aws_security_group.db_sg.id]
}