resource "aws_s3_bucket" "maika-assets" {  
  bucket = "maika-assets"
}

resource "aws_s3_bucket_policy" "allow-access-to-cloudfront" {
  bucket = aws_s3_bucket.maika-assets.id
  policy = file("s3-cloudfront-access.json")
}

resource "aws_s3_bucket_website_configuration" "maika-assets-web-config" {
  bucket = aws_s3_bucket.maika-assets.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

locals {
  s3_origin_id = "myS3Origin"
}

resource "aws_cloudfront_origin_access_control" "default" {
  name                              = "default"
  description                       = "Default Policy"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "maika-assets-distribution" {
  origin {
    domain_name = aws_s3_bucket.maika-assets.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.default.id
    origin_id   = local.s3_origin_id
    origin_shield {
      enabled              = true
      origin_shield_region = "sa-east-1"
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Static assets for Sistema Maika web application"
  default_root_object = "index.html"
  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id
  forwarded_values {
      query_string = false
  cookies {
        forward = "none"
      }
    }
  viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }
# Cache behavior with precedence 0
  ordered_cache_behavior {
    path_pattern     = "/content/immutable/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = local.s3_origin_id
forwarded_values {
      query_string = false
      headers      = ["Origin"]
cookies {
        forward = "none"
      }
    }
min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }
# Cache behavior with precedence 1
  ordered_cache_behavior {
    path_pattern     = "/content/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id
forwarded_values {
      query_string = false
cookies {
        forward = "none"
      }
    }
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }
price_class = "PriceClass_All"
restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
tags = {
    Environment = "production"
  }
viewer_certificate {
    cloudfront_default_certificate = true
  }
}
