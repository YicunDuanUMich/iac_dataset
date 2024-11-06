resource "aws_db_instance" "default" {
  allocated_storage    = 20
  engine               = "mysql"
  instance_class       = "db.t3.micro"
  username             = "foo"
  password             = "foobarbaz"
}

resource "aws_db_snapshot" "test" {
  db_instance_identifier = aws_db_instance.default.identifier
  db_snapshot_identifier = "testsnapshot1234"
}