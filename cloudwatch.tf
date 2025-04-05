resource "aws_cloudwatch_log_metric_filter" "info_log_filter" {
  name           = "info-count"
  log_group_name = aws_cloudwatch_log_group.http_api.name

  pattern = "?INFO"  # Filters log messages containing "[INFO]"

  metric_transformation {
    name      = "info-count"
    namespace = "/moviedb-api/${local.name_prefix}"
    value     = "1"
    unit      = "Count"
  }
}

resource "aws_cloudwatch_metric_alarm" "info_count_alarm" {
  alarm_name          = "${local.name_prefix}-info-count"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "info-count"
  namespace           = "/moviedb-api/${local.name_prefix}"
  period              = 60  # 1-minute interval
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "Alarm when [INFO] log count exceeds 5 in a 1-minute period"
  alarm_actions       = [aws_sns_topic.alert_topic.arn]
}