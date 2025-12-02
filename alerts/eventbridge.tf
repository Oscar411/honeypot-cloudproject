#Event bridge 

resource "aws_cloudwatch_event_rule" "guardduty_findings" {
  name        = "guardduty-findings-rule"
  description = "Capture GuardDuty findings and forward to Lambda"
  event_pattern = jsonencode({
    "source"      : ["aws.guardduty"],
    "detail-type" : ["GuardDuty Finding"]
  })
}

# EVENTBRIDGE TARGET (LAMBDA)
#were gonna need to make sure the naming conventions match when we make lambda 

# resource "aws_cloudwatch_event_target" "gd_to_lambda" {
#  rule      = aws_cloudwatch_event_rule.guardduty_findings.name
#  target_id = "send-to-lambda"
#  arn       = aws_lambda_function.alert_forwarder.arn  
# }

# ALLOW EVENTBRIDGE TO INVOKE LAMBDA

# resource "aws_lambda_permission" "allow_eventbridge" {
#  statement_id  = "AllowExecutionFromEventBridge"
#  action        = "lambda:InvokeFunction"
#  function_name = aws_lambda_function.alert_forwarder.function_name
#  principal     = "events.amazonaws.com"
#  source_arn    = aws_cloudwatch_event_rule.guardduty_findings.arn
# }

