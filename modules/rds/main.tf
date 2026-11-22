variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "db_instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "db_name" {
  type    = string
  default = "inventory"
}

variable "db_username" {
  type    = string
  default = "inventory"
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "rds_security_group_id" {
  type = string
}

output "rds_endpoint" {
  value = aws_db_instance.main.endpoint
}

output "rds_address" {
  value = aws_db_instance.main.address
}

resource "aws_db_subnet_group" "main" {
  name       = "inovo-db-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = { Name = "inovo-db-subnet-group" }
}

resource "aws_db_instance" "main" {
  identifier       = "inovo-db"
  engine           = "postgres"
  engine_version   = "16.1"
  instance_class   = var.db_instance_class
  allocated_storage = 20
  db_name          = var.db_name
  username         = var.db_username
  password         = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.rds_security_group_id]
  backup_retention_period = 0
  multi_az               = false
  storage_encrypted      = true

  tags = { Name = "inovo-db" }
}
