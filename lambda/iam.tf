# IAM role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "honeypot_alert_lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

# Policy with least-necessary permissions (S3 restricted to provided bucket)
resource "aws_iam_policy" "lambda_policy" {
  name = "honeypot_alert_lambda_policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ec2:CreateSnapshot",
          "ec2:DescribeInstances",
          "ec2:DescribeVolumes",
          "ec2:CreateTags"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:GetObject"
        ],
        Resource = [
          "arn:aws:s3:::${var.metadata_bucket}",
          "arn:aws:s3:::${var.metadata_bucket}/*"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "secretsmanager:GetSecretValue"
        ],
        Resource = [
          var.slack_secret_arn == "" ? "*" : var.slack_secret_arn,
          var.thehive_secret_arn == "" ? "*" : var.thehive_secret_arn
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}