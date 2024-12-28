terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.75"
    }
  }

  required_version = "~> 1.9.8"
}

provider "aws" {
  region = "us-east-1"
  profile = "admin-1"

  assume_role {
    role_arn = "arn:aws:iam::590184057477:role/yicun-iac"
  }
}

resource "aws_route53_zone" "main" {
  name = "example53.com"
}

resource "aws_route53_health_check" "primary_health_check" {
  fqdn              = "primary.example53.com"
  port              = 80
  type              = "HTTP"
  resource_path     = "/"
  failure_threshold = 3
}

resource "aws_route53_record" "primary_record" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "example53.com"
  type    = "A"
  ttl     = "60"
  records = ["192.0.2.101"]
  set_identifier = "primary-endpoint"

  failover_routing_policy {
    type = "PRIMARY"
  }

  health_check_id = aws_route53_health_check.primary_health_check.id
}

resource "aws_route53_health_check" "secondary_health_check" {
  fqdn              = "secondary.example53.com"
  port              = 80
  type              = "HTTP"
  resource_path     = "/"
  failure_threshold = 3
}

resource "aws_route53_record" "secondary_record" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "example53.com"
  type    = "A"
  ttl     = "60"
  records = ["192.0.2.102"] 
  set_identifier = "secondary-endpoint"
  
  failover_routing_policy {
    type = "SECONDARY"
  }

  health_check_id = aws_route53_health_check.secondary_health_check.id
}