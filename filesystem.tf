resource "aws_efs_file_system" "example" {

  lifecycle {
    prevent_destroy = "${var.production}"
  }

  tags {
    Name = "Example filesystem"
  }
}

resource "aws_efs_mount_target" "example-mount-1" {
  file_system_id = "${aws_efs_file_system.example.id}"
  subnet_id      = "${data.aws_subnet_ids.default.ids[0]}"
  security_groups = ["${aws_security_group.efs.id}"]
}
resource "aws_efs_mount_target" "example-mount-2" {
  file_system_id = "${aws_efs_file_system.example.id}"
  subnet_id      = "${data.aws_subnet_ids.default.ids[1]}"
  security_groups = ["${aws_security_group.efs.id}"]
}
resource "aws_efs_mount_target" "example-mount-3" {
  file_system_id = "${aws_efs_file_system.example.id}"
  subnet_id      = "${data.aws_subnet_ids.default.ids[2]}"
  security_groups = ["${aws_security_group.efs.id}"]
}
