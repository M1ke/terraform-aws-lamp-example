resource "aws_efs_file_system" "example" {

  lifecycle {
    prevent_destroy = true
  }

  tags {
    Name = "Example filesystem"
  }
}

data "aws_subnet_ids" "default" {
  vpc_id = "${var.vpc_id}"
}


resource "aws_efs_mount_target" "example-mount-1" {
  file_system_id = "${aws_efs_file_system.example.id}"
  subnet_id      = "${data.aws_subnet_ids.default.ids[0]}"
}
resource "aws_efs_mount_target" "example-mount-2" {
  file_system_id = "${aws_efs_file_system.example.id}"
  subnet_id      = "${data.aws_subnet_ids.default.ids[1]}"
}
resource "aws_efs_mount_target" "example-mount-3" {
  file_system_id = "${aws_efs_file_system.example.id}"
  subnet_id      = "${data.aws_subnet_ids.default.ids[2]}"
}
