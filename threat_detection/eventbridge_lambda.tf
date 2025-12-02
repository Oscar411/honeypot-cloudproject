# EventBridge Rule for Guard Duty findings

resource "aws_cloudwatch_event_rule" "guardduty_findings" {
  name        = "GuardDutyToLambda"
  description = "Forward GuardDuty findings to Lambda"

  event_pattern = <<EOF
{
  "source": ["aws.guardduty"],
  "detail-type": ["GuardDuty Finding"]
}
EOF
}

# Eventbridge Target (Lambda)

# resource "aws_cloudwatch_event_target" "guardduty_to_lambda" {
#  rule      = aws_cloudwatch_event_rule.guardduty_findings.name
#  target_id = "GuardDutyLambdaTarget"
#  arn       = aws_lambda_function.my_lambda.arn
# }

# Lambda Permission for EventBridge

# resource "aws_lambda_permission" "allow_events" {
#  statement_id  = "AllowExecutionFromEventBridge"
#  action        = "lambda:InvokeFunction"
#  function_name = aws_lambda_function.my_lambda.function_name     
#  principal     = "events.amazonaws.com"
#  source_arn    = aws_cloudwatch_event_rule.guardduty_findings.arn
#  }
