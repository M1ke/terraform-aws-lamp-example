resource "aws_efs_file_system" "example" {

  lifecycle {
    # Can't use the "production" variable so we'll
    # just set this to be safe - data loss hurts
    prevent_destroy = true
  }

  tags = {
    Name = "Example filesystem"
  }
}

resource "aws_efs_mount_target" "example-mount" {
  for_each      = toset(data.aws_subnets.default.ids)

  file_system_id = aws_efs_file_system.example.id
  subnet_id      = each.value
  security_groups = [aws_security_group.efs.id]
}
