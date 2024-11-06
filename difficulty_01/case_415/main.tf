resource "aws_db_instance" "default" {
  allocated_storage    = 100
  engine               = "mysql"
  instance_class       = "db.t3.micro"
  username             = "foo"
  password             = "foobarbaz"
  storage_type        = "io1"
}