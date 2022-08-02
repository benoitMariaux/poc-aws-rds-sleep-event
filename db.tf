resource "aws_db_instance" "db" {
  allocated_storage    = 10
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t3.micro"
  db_name              = var.db_name
  username             = var.db_username
  password             = var.db_password
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
  publicly_accessible  = true
}

output "db_host" {
  value = aws_db_instance.db.address
}

output "db_port" {
  value = aws_db_instance.db.port
}

output "db_username" {
  value = aws_db_instance.db.username
}

output "db_password" {
  value = var.db_password
}

output "db_name" {
  value = var.db_name
}