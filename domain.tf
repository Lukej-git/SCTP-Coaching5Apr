data "aws_route53_zone" "zone" {
  name = "sctp-sandbox.com"
}

## ACM Module for creation of ACM Cert
module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "5.1.1"

  domain_name  = "shortener.lac.com"
  zone_id      = data.aws_route53_zone.zone.zone_id

  validation_method = "DNS"

  subject_alternative_names = [
    "shortener.my-domain.com",
    "app.lac.my-domain.com",
  ]

  wait_for_validation = true

  tags = {
    Name = "shortener.lac.com"
  }
}

## API Gateway + Custom Domain

resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = "lac_shortener"
  type    = "A"

    alias {
    name                   = "lac_shortener"
    zone_id                = data.aws_route53_zone.zone.zone_id
    evaluate_target_health = false
    }
}