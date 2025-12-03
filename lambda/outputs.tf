output "lambda_function_arn" {
  value = aws_lambda_function.alert_forwarder.arn
}

output "eventbridge_rule_name" {
  value = aws_cloudwatch_event_rule.guardduty_rule.name
}