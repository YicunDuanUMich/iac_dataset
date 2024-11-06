resource "aws_db_instance" "default" {
  allocated_storage    = 20
  engine               = "mysql"
  instance_class       = "db.z1d.micro"
  username             = "foo"
  password             = "foobarbaz"
  skip_final_snapshot = true
}