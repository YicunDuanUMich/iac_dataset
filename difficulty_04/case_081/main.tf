provider "aws" {
  region = "us-east-1"
}

resource "aws_route53_zone" "primary" {
  name = "example53.com"
}

# Health check for the primary resource
resource "aws_route53_health_check" "primary_health_check" {
  fqdn              = "example.com"
  port              = 80
  type              = "HTTP"
  resource_path     = "/"
  failure_threshold = 3
  request_interval  = 30
}

# Primary A record with a health check (active endpoint)
resource "aws_route53_record" "primary_record" {
  zone_id           = aws_route53_zone.primary.zone_id
  name              = "example.com"
  type              = "A"
  ttl               = "60"
  records           = ["192.0.2.10"]
  set_identifier    = "primary"
  health_check_id   = aws_route53_health_check.primary_health_check.id

  failover_routing_policy {
    type = "PRIMARY"
  }
}

# Secondary A record without a health check (passive endpoint)
resource "aws_route53_record" "secondary_record" {
  zone_id           = aws_route53_zone.primary.zone_id
  name              = "example.com"
  type              = "A"
  ttl               = "60"
  records           = ["192.0.2.20"]
  set_identifier    = "secondary"

  failover_routing_policy {
    type = "SECONDARY"
  }
}