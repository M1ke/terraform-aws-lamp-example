resource "aws_db_instance" "example" {
  identifier = "example"
  allocated_storage = 20
  storage_type = "gp2"
  engine = "mysql"
  instance_class = "db.t2.micro"
  username = "root"
  password = "insecure-default-password"
  port = 3306
  publicly_accessible = false
  security_group_names = []
  vpc_security_group_ids = [
    "${aws_security_group.db.id}"]
  parameter_group_name = "${aws_db_parameter_group.example.name}"
  multi_az = false
  backup_retention_period = 0
  backup_window = "01:00-02:00"
  maintenance_window = "mon:06:00-mon:06:30"
  final_snapshot_identifier = "example-db-final"
  iam_database_authentication_enabled = true
  monitoring_interval = 0
  skip_final_snapshot = false
  apply_immediately = true
  enabled_cloudwatch_logs_exports = ["error", "slowquery"]

  tags {
  }
}

output "db-endpoint" {
  value = "${aws_db_instance.example.endpoint}"
}

resource "aws_db_parameter_group" "basic" {
  name   = "basic"
  family = "mysql5.6"
  description = "Minor tweaks to regular mysql config"

  parameter {
    name  = "time_zone"
    value = "europe/dublin"
  }
}
