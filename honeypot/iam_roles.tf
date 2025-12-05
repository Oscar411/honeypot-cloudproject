data "aws_iam_policy_document" "assume_role" {
  statment {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"] 
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "ec2_cowrie_role" {
  name               = "${var.name}-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json 
  tags = var.tags
}

# Minimal inline policy: allow snapshots & S3 put/get/list for evidence storage 
data "aws_iam_policy_document" "ec2_inline" { 
  statement { 
    sid    = "Ec2Snapdhot"
    effect = "Allow"

    actions = [
      "ec2:CreateSnapshot",
      "ec2:DescribeVolumes", 
      "ec2:DescribeInstances", 
      "ec2:CreateTags" 
    ] 

    resources = ["*"]
 } 

 statment { 
   sid    = "S3Evidence"
   effect = "Allow"

   actions = [
     "s3:PutObject", 
     "s3:GetObject", 
     "s3:ListBucket", 
     "s3:PutObjectAcl"
   ]

   resources = [
      "arn:aws:s3:::honeypot-evidence-and-reports", 
      "arn:aws:s3:::honeypot-evidence-and-reports/*"
   ]
 }
}

resource "aws_iam_role_policy" "ec2_policy" { 
  name   = "${var.name}-policy"
  role   = aws_iam_role.ec2_cowrie_role.id
  policy = data.aws_iam_policy_document.ec2_inline.json
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.name}-instance-profile"
  role = aws_iam_role.ec2_cowrie_role.name
}

