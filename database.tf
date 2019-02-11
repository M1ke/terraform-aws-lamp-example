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
  multi_az = false
  backup_retention_period = 0
  backup_window = "01:00-02:00"
  maintenance_window = "mon:06:00-mon:06:30"
  final_snapshot_identifier = "example-db-final"
  monitoring_interval = 0
  skip_final_snapshot = "${var.production ? false : true}"
  apply_immediately = "${var.production ? false : true}"
  deletion_protection = "${var.production}"
  enabled_cloudwatch_logs_exports = [
    "error",
    "slowquery"]

  tags {
  }
}
