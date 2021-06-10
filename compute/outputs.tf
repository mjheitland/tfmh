#--- compute/outputs.tf
output "alb_dns" {
  value = aws_lb.alb.dns_name
}

output "alb_name" {
  value = aws_lb.alb.name
}

output "asg_name" {
  value = aws_autoscaling_group.asg.name
}

output "ec2_windows" {
  value = aws_instance.windows.id
}