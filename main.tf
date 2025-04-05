locals {
  name_prefix = "LAC"
}

## ACM Module for creation of ACM Cert
module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "5.1.1"

  domain_name  = "shortener.lac.com"
  zone_id      = data.aws_route53_zone.sctp_zone.zone_id

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
  zone_id = data.aws_route53_zone.sctp_zone.zone_id
  name    = "LAC_shortener"
  type    = "A"

    alias {
    name                   = "LAC_shortener"
    zone_id                = data.aws_route53_zone.sctp_zone.zone_id
    evaluate_target_health = false
    }
}

resource "aws_api_gateway_domain_name" "shortener" {
  domain_name              = "shortener.lac.com"
  regional_certificate_arn = module.acm.acm_certificate_arn.arn

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

# resource "aws_api_gateway_base_path_mapping" "shortener" {
#   api_id      = aws_api_gateway_rest_api.shortener.id
#   stage_name  = aws_api_gateway_stage.shortener.stage_name
#   domain_name = aws_api_gateway_domain_name.shortener.domain_name
# }

## Logging ONLY blocked requests for WAF

# resource "aws_wafv2_web_acl_logging_configuration" "api_gw_waf_logging" {
#   resource_arn = aws_wafv2_web_acl.api_gw_waf.arn
#   log_destination_configs = [
#     aws_cloudwatch_log_group.waf_logs.arn
#   ]

#   logging_filter {
#     # Default behavior when no filters match
#     default_behavior = "DROP" # means "do not log" if no filter matches

#     filter {
#       behavior    = "KEEP" # keep logs if the condition matches
#       requirement = "MEETS_ANY"

#       condition {
#         action_condition {
#           action = "BLOCK"
#         }
#       }
#     }
#   }
# }

## API Gateway POST Resources

############# CREATE URL RESOURCES#####################
# resource "aws_api_gateway_resource" "newurl" {}

# resource "aws_api_gateway_method" "post_method" {}

# resource "aws_api_gateway_integration" "post_integration" {
#   rest_api_id             =
#   resource_id             = 
#   http_method             = 
#   integration_http_method = "POST"
#   type                    = "AWS_PROXY"
#   uri                     = 
# }

# resource "aws_api_gateway_method_response" "response_200" {
#   rest_api_id = aws_api_gateway_rest_api.api.id
#   resource_id = aws_api_gateway_resource.newurl.id
#   http_method = aws_api_gateway_method.post_method.http_method
#   status_code = "200"

#   response_models = {
#     "application/json" = "Empty"
#   }
# }

## API Gateway GET Resources
# resource "aws_api_gateway_resource" "geturl" {}

# resource "aws_api_gateway_method" "get_method" {}

# resource "aws_api_gateway_integration" "get_integration" {
#   rest_api_id             =
#   resource_id             =
#   http_method             =
#   integration_http_method = "POST"
#   type                    = "AWS"
#   uri                     = #uri?
#   request_templates = {
#     "application/json" = <<EOF
#     { 
#       "short_id": "$input.params('shortid')" 
#     }
#     EOF
#   }
# }

# resource "aws_api_gateway_method_response" "response_302" {
#   rest_api_id =
#   resource_id =
#   http_method =
#   status_code = "302"

#   response_parameters = {
#     "method.response.header.Location" = true
#   }
# }

# resource "aws_api_gateway_integration_response" "get_integration_response" {
#   rest_api_id =
#   resource_id =
#   http_method =
#   status_code = aws_api_gateway_method_response.response_302.status_code

#   response_parameters = {
#     "method.response.header.Location" = "integration.response.body.location"
#   }
#   depends_on = [
#     aws_api_gateway_integration.get_integration
#   ]
# }
