resource "aws_lightsail_key_pair" "lg_key_pair" {
  name       = "importing"
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "aws_lightsail_instance" "custom" {
  name              = "custom"
  availability_zone = "us-east-1b"
  blueprint_id      = "wordpress"
  bundle_id         = "nano_2_0"
  key_pair_name = aws_lightsail_key_pair.lg_key_pair.name
 }