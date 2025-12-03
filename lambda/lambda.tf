provider "aws" {
  region = var.aws_region
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda_alert_forwarder.py"
  output_path = "${path.module}/lambda_alert_forwarder.zip"
}

resource "aws_lambda_function" "alert_forwarder" {
  function_name = "honeypot_alert_forwarder"
  handler       = "lambda_alert_forwarder.lambda_handler"
  runtime       = "python3.10"
  role          = aws_iam_role.lambda_role.arn

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = filebase64sha256(data.archive_file.lambda_zip.output_path)

  environment {
    variables = {
      METADATA_BUCKET           = var.metadata_bucket
      DEFAULT_HONEYPOT_INSTANCE = var.default_honeypot_instance
      SLACK_SECRET_ARN          = var.slack_secret_arn
      THEHIVE_SECRET_ARN        = var.thehive_secret_arn
    }
  }

  timeout     = 120
  memory_size = 512
}