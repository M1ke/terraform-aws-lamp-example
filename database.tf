//resource "aws_db_instance" "example" {
//  identifier = "example"
//  allocated_storage = 5
//  storage_type = "gp2"
//  engine = "mysql"
//  instance_class = "db.t2.micro"
//  username = "root"
//  password = "insecure-default-password"
//  port = 3306
//  publicly_accessible = false
//  security_group_names = []
//  vpc_security_group_ids = [
//    "${aws_security_group.db.id}"]
//  parameter_group_name = "${aws_db_parameter_group.example.name}"
//  multi_az = false
//  backup_retention_period = 0
//  backup_window = "01:00-02:00"
//  maintenance_window = "mon:06:00-mon:06:30"
//  final_snapshot_identifier = "example-db-final"
//  iam_database_authentication_enabled = true
//  monitoring_interval = 0
//  skip_final_snapshot = false
//  apply_immediately = true
//  enabled_cloudwatch_logs_exports = ["error", "slowquery"]
//
//  tags {
//  }
//}

//output "db-endpoint" {
//  value = "${aws_db_instance.example.endpoint}"
//}

resource "aws_db_parameter_group" "example" {
  name   = "example"
  family = "mysql5.6"
  description = "example"

  parameter {
    name  = "time_zone"
    value = "europe/dublin"
  }

  // This can impact various parts of how the database functions. The main differences
  // are that file per table is harder to restore as the database size increases. However
  // file per table makes it easier to regain hard disk space after data is deleted
  parameter {
    name  = "innodb_file_per_table"
    value = "1"
  }

  parameter {
    apply_method = "pending-reboot"
    name  = "innodb_buffer_pool_size"
    value = "{DBInstanceClassMemory*1/2}"
  }

  parameter {
    name  = "log_output"
    value = "file"
  }

  parameter {
    name  = "log_warnings"
    value = "0"
  }

  parameter {
    name  = "general_log"
    value = "0"
  }

  parameter {
    name  = "slow_query_log"
    value = "1"
  }

  parameter {
    name  = "log_queries_not_using_indexes"
    value = "0"
  }

  parameter {
    name  = "log_bin_trust_function_creators"
    value = "1"
  }

  tags {
  }
}
