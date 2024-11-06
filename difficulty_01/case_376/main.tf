resource "aws_lightsail_certificate" "test" {
  name                      = "test"
  domain_name               = "testdomain.com"
  subject_alternative_names = ["www.testdomain.com"]
}