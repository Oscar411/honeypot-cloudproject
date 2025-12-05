# ─────────────────────────────────────────────
# NETWORK MODULE
# ─────────────────────────────────────────────
module "network" {
  source = "./network"

  project_name = var.project_name
}


# ─────────────────────────────────────────────
# S3 MODULE
# ─────────────────────────────────────────────
module "s3" {
  source = "./s3"

  project_name = var.project_name
}


# ─────────────────────────────────────────────
# HONEYPOT EC2 MODULE
# ─────────────────────────────────────────────
module "honeypot" {
  source = "./honeypot"

  project_name = var.project_name
  vpc_id       = module.network.vpc_id
  subnet_id    = module.network.public_subnet_id
}


# ─────────────────────────────────────────────
# LAMBDA MODULE (Alert Forwarder)
# ─────────────────────────────────────────────
module "lambda" {
  source = "./lambda"

  project_name          = var.project_name
  metadata_bucket       = module.s3.bucket_name
  slack_secret_arn      = var.slack_secret_arn
  thehive_secret_arn    = var.thehive_secret_arn
  default_honeypot_instance = module.honeypot.instance_id

  eventbridge_rule_arn = module.threat_detection.guardduty_rule_arn
}


# ─────────────────────────────────────────────
# THREAT DETECTION MODULE
# ─────────────────────────────────────────────
module "threat_detection" {
  source = "./threat_detection"

  project_name  = var.project_name
  lambda_arn    = module.lambda.lambda_function_arn
}

