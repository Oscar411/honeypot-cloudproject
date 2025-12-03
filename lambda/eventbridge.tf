resource "aws_cloudwatch_event_rule" "guardduty_rule" {
  name        = "honeypot_guardduty_findings"
  description = "Forward GuardDuty findings to honeypot Lambda"

  event_pattern = <<EOF
{
  "source": ["aws.guardduty"],
  "detail-type": ["GuardDuty Finding"]
}
EOF
}

resource "aws_cloudwatch_event_target" "guardduty_target" {
  rule      = aws_cloudwatch_event_rule.guardduty_rule.name
  target_id = "honeypot_lambda_target"
  arn       = aws_lambda_function.alert_forwarder.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.alert_forwarder.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.guardduty_rule.arn
}