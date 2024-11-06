provider "aws" {
  region = "us-west-1"
}

resource "aws_s3_bucket" "video_content" {
}

locals {
  s3_origin_id = "s3_video_content_origin"
}

resource "aws_cloudfront_origin_access_control" "netflix_cf" {
  name                              = "netflix_cf"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "netflix_distribution" {
  origin {
    domain_name              = aws_s3_bucket.video_content.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.netflix_cf.id
    origin_id                = local.s3_origin_id
  }

  enabled             = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
  }

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["US", "CA", "GB", "DE"]
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

# Route53
resource "aws_route53_zone" "netflix_zone" {
  name = "netflix.com"
}

resource "aws_route53_record" "cdn_ipv4" {
  type    = "A"
  name    = "cdn"
  zone_id = aws_route53_zone.netflix_zone.zone_id

  alias {
    name                   = aws_cloudfront_distribution.netflix_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.netflix_distribution.hosted_zone_id
    evaluate_target_health = true
  }
}