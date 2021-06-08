#--- S3 user_data bucket (contains additional user data to overcome 16k limit for user data)
data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  user_data_bucket_name = "${var.project_name}-user-data-${local.account_id}"
  user_data_file_name = "user_data.sh"
  user_data_s3_key = "user_data/${terraform.workspace}/${var.region}/${local.user_data_file_name}"
}

resource "aws_s3_bucket_public_access_block" "user_data" {
  bucket = aws_s3_bucket.user_data.id

  # Whether Amazon S3 should block public bucket policies for this bucket. Defaults to false. 
  # Enabling this setting does not affect the existing bucket policy. When set to true causes Amazon S3 to:
  # Reject calls to PUT Bucket policy if the specified bucket policy allows public access.
  block_public_acls = true

  # Whether Amazon S3 should block public bucket policies for this bucket. Defaults to false. 
  # Enabling this setting does not affect the existing bucket policy. When set to true causes Amazon S3 to:
  # Reject calls to PUT Bucket policy if the specified bucket policy allows public access.
  block_public_policy = true

  # Whether Amazon S3 should ignore public ACLs for this bucket. Defaults to false. 
  # Enabling this setting does not affect the persistence of any existing ACLs and doesn't prevent new public ACLs from being set. When set to true causes Amazon S3 to:
  # Ignore public ACLs on this bucket and any objects that it contains.
  ignore_public_acls = true

  # Whether Amazon S3 should restrict public bucket policies for this bucket. Defaults to false. 
  # Enabling this setting does not affect the previously stored bucket policy, except that public and cross-account access within the public bucket policy, 
  # including non-public delegation to specific accounts, is blocked. When set to true:
  # Only the bucket owner and AWS Services can access this buckets if it has a public policy.
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "user_data" {
  bucket = local.user_data_bucket_name

  # The canned ACL to apply. Defaults to "private". Conflicts with grant.
  # "private": Owner gets FULL_CONTROL. No one else has access rights (default).
  acl = "private"

  # A boolean that indicates all objects (including any locked objects) should be deleted from the bucket 
  # so that the bucket can be destroyed without error. These objects are not recoverable.
  force_destroy = true

  # prevent accidental deletion of this bucket
  # (if you really have to destroy this bucket, change this value to false and reapply, then run destroy)
  lifecycle {
    prevent_destroy = false
  }

  # enable versioning so we can see the full revision history of our state file
  versioning {
    enabled = false
  }

  # enable server-side encryption by default
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        # kms_master_key_id = aws_kms_key.ROOT-KMS-S3.arn
        # sse_algorithm     = "aws:kms"
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_s3_bucket_object" "user_data" {
  bucket   = aws_s3_bucket.user_data.id
  key      = local.user_data_s3_key
  source   = "${path.module}/scripts/${local.user_data_file_name}"
  etag     = filemd5("${path.module}/scripts/${local.user_data_file_name}") 
}


#--- EC2 

resource "aws_key_pair" "keypair" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)
}

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-2.0.*-x86_64-gp2"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

resource "aws_launch_configuration" "asg" {
  name_prefix   = format("%s-${terraform.workspace}", var.project_name)
  image_id      = data.aws_ami.amazon_linux_2.id
  instance_type = var.instance_type
  key_name      = aws_key_pair.keypair.id

  security_groups = [var.sg_id]

  associate_public_ip_address = false

  iam_instance_profile = aws_iam_instance_profile.asg.name

  lifecycle {
    create_before_destroy = true
  }

  user_data = <<EOF
#!/bin/bash
# user data runs under root account and starts in /!
cd /usr/local/bin
aws s3 cp "s3://${local.user_data_bucket_name}/${local.user_data_s3_key}" ${local.user_data_file_name}
chmod +x ${local.user_data_file_name}
sed -i '1,$s/$TF_INSTANCE_TYPE/${var.instance_type}/g' ./${local.user_data_file_name}
./${local.user_data_file_name}
  EOF
}

resource "aws_iam_instance_profile" "asg" {
  name = format("%s-asg-profile-${terraform.workspace}", var.project_name)
  role = aws_iam_role.asg.name
  lifecycle {
    create_before_destroy = true
  }
  tags = {
    Name         = format("%s_asg", var.project_name)
    project_name = var.project_name
  }
}

resource "aws_iam_role" "asg" {
  name = format("%s-asg-role-${terraform.workspace}", var.project_name)
  path = "/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

resource "aws_iam_role_policy" "asg" {
  name = format("%s-asg-policy-${terraform.workspace}", var.project_name)
  role = aws_iam_role.asg.id

  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
          "s3:*"
        ],
        "Effect": "Allow",
        "Resource": [
                "arn:aws:s3:::${local.user_data_bucket_name}",
                "arn:aws:s3:::${local.user_data_bucket_name}/*"
            ]
      }
    ]
  }
  EOF
}


#--- Auto-Scaling

resource "aws_autoscaling_group" "asg" {
  depends_on = [aws_launch_configuration.asg]
  lifecycle {
    create_before_destroy = true
  }

  name_prefix               = format("%s-asg-${terraform.workspace}", var.project_name)
  vpc_zone_identifier       = var.subpub_ids
  max_size                  = 1
  min_size                  = 1
  wait_for_elb_capacity     = 1
  desired_capacity          = 1
  health_check_grace_period = 60
  force_delete              = false
  launch_configuration      = aws_launch_configuration.asg.id
  target_group_arns         = [aws_alb_target_group.albtargetgrp.arn]

  tags = [
    {
      "key"                 = "Name"
      "value"               = format("%s_ec2", var.project_name)
      "propagate_at_launch" = true
    },
    {
      "key"                 = "project_name"
      "value"               = format("%s_ec2", var.project_name)
      "propagate_at_launch" = true
    }
  ]
}

resource "aws_autoscaling_policy" "scale_up" {
  name                   = format("%s-asg-scale-up-${terraform.workspace}", var.project_name)
  scaling_adjustment     = 2
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.asg.name
}

resource "aws_cloudwatch_metric_alarm" "scale_up_alarm" {
  alarm_name                = format("%s-asg-high-cpu-${terraform.workspace}", var.project_name)
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = "2"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = "120"
  statistic                 = "Average"
  threshold                 = "80"
  insufficient_data_actions = []

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg.name
  }

  alarm_description = "EC2 CPU Utilization"
  alarm_actions     = [aws_autoscaling_policy.scale_up.arn]
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = format("%s-asg-scale-down-${terraform.workspace}", var.project_name)
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 600
  autoscaling_group_name = aws_autoscaling_group.asg.name
}

resource "aws_cloudwatch_metric_alarm" "scale_down_alarm" {
  alarm_name                = format("%s-asg-low-cpu-${terraform.workspace}", var.project_name)
  comparison_operator       = "LessThanThreshold"
  evaluation_periods        = "5"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = "120"
  statistic                 = "Average"
  threshold                 = "30"
  insufficient_data_actions = []

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg.name
  }

  alarm_description = "EC2 CPU Utilization"
  alarm_actions     = [aws_autoscaling_policy.scale_down.arn]
}



#--- Load Balancer

resource "aws_security_group" "alb" {
  name_prefix = format("%s-sg-${terraform.workspace}", var.project_name)
  vpc_id      = var.vpc_id
  # Allow all inbound HTTP requests
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Allow all outbound requests
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "alb" {
  # "name_prefix": "tfmh-default-" is too long! 
  name_prefix        = format("%s", var.project_name)
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.subpub_ids
  tags = {
    Name         = format("%s_alb", var.project_name)
    project_name = var.project_name
  }
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.albtargetgrp.arn
  }
}

resource "aws_alb_target_group" "albtargetgrp" {
  name     = format("%s-lbtrggrp-${terraform.workspace}", var.project_name)
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_autoscaling_attachment" "asgattachment" {
  autoscaling_group_name = aws_autoscaling_group.asg.id
  alb_target_group_arn   = aws_alb_target_group.albtargetgrp.arn
}
