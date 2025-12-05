resource "aws_security_group" "honeypot_sg" {
  name        = "${var.name}-sg"
  description = "Security group for Cowrie honeypot" 
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.name}-sg" 
  }) 
}

# Inbound: SSH (22) for admin, Cowrie SSH emulator (2222), Telnet (23), HTTP (80)
resource "aws_security_group_rule" "ingress_ssh_admin" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp" 
  cidr_blocks              = [var.allowed_cidr]
  security_group_id        = aws_security_group.honeypot_sg.id
  descriiption             = "Admin SSH (monitoring/maintenance)"
}

resource "aws_security_group_rule" "ingress_cowrie_ssh" {
  type                     = "ingress"
  from_port                = 2222
  to_port                  = 2222
  protocol                 = "tcp"
  cidr_blocks              = [var.allowed_cidr]
  security_group_id        = aws_security_group.honeypot_sg.id
  description              = "Telnet (Cowrie)"
}

resource "aws_security_group_rule" "ingress_http" {
  type                     = "ingress"
  from_port                = 80 
  to_port                  = 80
  protocol                 = "tcp"
  cidr_blocks              = [var.allowed_cidr]
  security_group_id        = aws_security_group.honeypot_sg.id
  description              = "HTTP"
}

# Allow outbound only to AWS services 
resource "aws_security_group_rule" "egress_all" {
  type                     = "egress"
  from_port                = 0
  to_port                  = 0 
  protocol                 = "-1" 
  cidr_blocks              = ["0.0.0.0/0"]
  security_group_id        = aws_security_group.honeypot_sg.id
  description              = "Allow outbound to S3 and SNS" 
}

