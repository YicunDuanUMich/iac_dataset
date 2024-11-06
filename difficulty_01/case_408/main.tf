resource "aws_db_instance" "default" {
  allocated_storage    = 20
  engine               = "postgres"
  instance_class       = "db.t4g.large"
  username             = "foo"
  password             = "foobarbaz"
}