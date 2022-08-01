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