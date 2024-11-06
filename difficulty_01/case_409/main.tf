resource "aws_db_instance" "default" {
  allocated_storage    = 20
  engine               = "postgres"
  instance_class       = "db.z1d.micro"
  username             = "foo"
  password             = "foobarbaz"
}