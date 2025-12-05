output "honeypot_ec2_public_ip" {
  description = "Public IP of the honeypot EC2 instance"
  value       = module.honeypot.public_ip
}

output "lambda_function_arn" {
  description = "ARN of the alert-forwarder Lambda"
  value       = module.lambda.lambda_function_arn
}

output "evidence_bucket" {
  description = "S3 bucket storing GuardDuty metadata/evidence"
  value       = module.s3.bucket_name
}

