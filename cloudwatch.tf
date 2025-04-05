# resource "aws_cloudwatch_log_metric_filter" "info_log_filter" {
#   name           = "info-count"
#   log_group_name = aws_cloudwatch_log_group.http_api.name

#   pattern = "?INFO"  # Filters log messages containing "[INFO]"

#   metric_transformation {
#     name      = "info-count"
#     namespace = "/moviedb-api/${local.name_prefix}"
#     value     = "1"
#     unit      = "Count"
#   }
# }

# resource "aws_cloudwatch_metric_alarm" "info_count_alarm" {
#   alarm_name          = "${local.name_prefix}-info-count"
#   comparison_operator = "GreaterThanThreshold"
#   evaluation_periods  = 1
#   metric_name         = "info-count"
#   namespace           = "/moviedb-api/${local.name_prefix}"
#   period              = 60  # 1-minute interval
#   statistic           = "Sum"
#   threshold           = 5
#   alarm_description   = "Alarm when [INFO] log count exceeds 5 in a 1-minute period"
#   alarm_actions       = [aws_sns_topic.alert_topic.arn]
# }

resource "aws_wafv2_web_acl_logging_configuration" "api_gw_waf_logging" {
  resource_arn = aws_wafv2_web_acl.api_gw_waf.arn
  log_destination_configs = [
    aws_cloudwatch_log_group.waf_logs.arn
  ]

  logging_filter {
    # Default behavior when no filters match
    default_behavior = "DROP" # means "do not log" if no filter matches

    filter {
      behavior    = "KEEP" # keep logs if the condition matches
      requirement = "MEETS_ANY"

      condition {
        action_condition {
          action = "BLOCK"
        }
      }
    }
  }
}

resource "aws_wafv2_web_acl" "api_gw_waf" {
  name        = "rate-based-example"
  description = "Example of a Cloudfront rate based statement."
  scope       = "CLOUDFRONT"

  default_action {
    allow {}
  }

  rule {
    name     = "rule-1"
    priority = 1

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 10000
        aggregate_key_type = "IP"

        scope_down_statement {
          geo_match_statement {
            country_codes = ["US", "NL"]
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "friendly-rule-metric-name"
      sampled_requests_enabled   = false
    }
  }

  tags = {
    Tag1 = "Value1"
    Tag2 = "Value2"
  }

  visibility_config {
    cloudwatch_metrics_enabled = false
    metric_name                = "friendly-metric-name"
    sampled_requests_enabled   = false
  }
}

resource "aws_cloudwatch_log_group" "waf_logs" {
  name = "waf_logs"

  tags = {
    Environment = "production"
    Application = "serviceA"
  }
}