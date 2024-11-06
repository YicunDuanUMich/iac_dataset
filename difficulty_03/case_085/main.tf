provider "aws" {
  region = "us-east-1"
}

resource "aws_route53_zone" "primary" {
  name = "example53.com"
}

resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "www.example.com"
  type    = "CNAME"
  ttl     = 300
  records = ["192.0.2.101"]
  set_identifier = "NA Endpoint"
  geolocation_routing_policy {
    continent = "NA"
  }
}

resource "aws_route53_record" "eu_geolocation_record" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "service.example53.com"
  type    = "A"
  ttl     = "60"
  records = ["192.0.2.102"]
  set_identifier = "EU Endpoint"

  geolocation_routing_policy {
    continent = "EU" 
  }
}
