output "latest_ami_id" {
  value = aws_ssm_document.create_ami.content
}