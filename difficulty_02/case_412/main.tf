resource "aws_db_instance" "default" {
  allocated_storage    = 20
  engine               = "mysql"
  instance_class       = "db.z1d.micro"
  username             = "foo"
  password             = "foobarbaz"
}

resource "aws_db_instance" "replica" {
  replicate_source_db = aws_db_instance.default.arn
  instance_class       = "db.z1d.micro"
  password             = "1234567"
}