resource "aws_lightsail_database" "test" {
  relational_database_name = "test"
  availability_zone        = "us-east-1a"
  master_database_name     = "testdatabasename"
  master_password          = "testdatabasepassword"
  master_username          = "test"
  blueprint_id             = "mysql_8_0"
  bundle_id                = "micro_1_0"
}