resouce "aws_security_group" "honeypot_sg"{
        name        = "honeypot-sg"
        description = "Security group for honeypot EC2 instance"
        vpc_id      = aws_vpc.honeypot_vpc.id

        ingress {
           description = "SSH"
           from_port   = 22
           to_port     = 22
           protocol    = "tcp"
           cidr_blocks = ["0.0.0.0/0"]
        }

        ingress {
           description = "HTTP"
           from_port   = 80
           to_port     = 80
	    protocol    = "tcp"
           cidr_blocks = ["0.0.0.0/0"]
        }

        egress {
           description = "Allow S3 and SNS"
           from_port   = 443
           to_port     = 443
           protocol    = "tcp"
           cidr_blocks = ["0.0.0.0/0"]
        } 

        tags = { Name = "honeypot-sg" }
} 
