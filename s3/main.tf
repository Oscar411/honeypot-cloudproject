resource "aws_s3_bucket" "honeypot_evidence" {
  bucket = "honeypot-evidence-and-reports"

  versioning {
    enabled = true
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "honeypot_evidence_sse" {
  bucket = aws_s3_bucket.honeypot_evidence.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = "alias/aws/s3"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "archive" {
  bucket = aws_s3_bucket.honeypot_evidence.id

  rule {
    id      = "archive-old-logs"
    enabled = true

    transition {
      days          = 30
      storage_class = "GLACIER"
    }
  }
}

