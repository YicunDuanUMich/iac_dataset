resource "aws_efs_file_system" "fs" {
  creation_token = "my-product"
}

resource "aws_efs_backup_policy" "policy" {
  file_system_id = aws_efs_file_system.fs.id

  backup_policy {
    status = "ENABLED"
  }
}