output "ec2_id" {
  value = aws_instance.ec2_project.id
}
output "ec2_public_ip" {
  value = aws_instance.ec2_project.public_ip
}