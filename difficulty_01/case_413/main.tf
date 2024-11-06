resource "aws_db_instance" "replica" {
  snapshot_identifier = "your identifier"
  instance_class       = "db.z1d.micro"
}