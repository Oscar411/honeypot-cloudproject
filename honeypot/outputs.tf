output "instance_id" {
  value = aws_instance.cowrie.id 
}

output "public_ip" { 
  value = aws_instance.cowrie.public_ip
}

output "public_dns" { 
  value = aws_instance.cowrie.public_dns
}

output "security_group_id" {
  value = aws_security_group.honeypot_sg.id
}

output "iam_instance_profile" { 
  value = aws_iam_instance_profile.ec2_profile.name
} 

