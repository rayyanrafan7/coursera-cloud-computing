data "aws_vpc" "main" {
  default = true
}

data "aws_subnets" "subneta" {
  filter {
    name   = "availability-zone"
    values = [var.az[0]]
  }

  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}

data "aws_subnets" "subnetb" {
  filter {
    name   = "availability-zone"
    values = [var.az[1]]
  }

  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}

resource "aws_s3_bucket" "raw" {
  bucket        = var.raw-s3-bucket
  force_destroy = true

  tags = {
    assessment = var.module-tag
  }
}

resource "aws_s3_bucket" "finished" {
  bucket        = var.finished-s3-bucket
  force_destroy = true

  tags = {
    assessment = var.module-tag
  }
}

resource "aws_lb" "lb" {
  name               = var.elb-name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.vpc_security_group_ids]
  subnets            = [data.aws_subnets.subneta.ids[0], data.aws_subnets.subnetb.ids[0]]

  enable_deletion_protection = false

  tags = {
    assessment = var.module-tag
  }
}

resource "aws_lb_target_group" "alb-lb-tg" {
  name        = var.tg-name
  target_type = "instance"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.main.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    assessment = var.module-tag
  }
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb-lb-tg.arn
  }
}

resource "aws_launch_template" "mp1-lt" {
  name                                 = var.lt-name
  image_id                             = var.imageid
  instance_initiated_shutdown_behavior = "terminate"
  instance_type                        = var.instance-type
  key_name                             = var.key-name
  user_data                            = filebase64(var.install-env-file)

  monitoring {
    enabled = false
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [var.vpc_security_group_ids]
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name       = var.module-tag
      assessment = var.module-tag
    }
  }

  tags = {
    assessment = var.module-tag
  }
}

resource "aws_autoscaling_group" "bar" {
  name                      = var.asg-name
  desired_capacity          = var.desired
  max_size                  = var.max
  min_size                  = var.min
  health_check_grace_period = 300
  health_check_type         = "ELB"
  target_group_arns         = [aws_lb_target_group.alb-lb-tg.arn]
  vpc_zone_identifier       = [data.aws_subnets.subneta.ids[0], data.aws_subnets.subnetb.ids[0]]

  launch_template {
    id      = aws_launch_template.mp1-lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = var.module-tag
    propagate_at_launch = true
  }

  tag {
    key                 = "assessment"
    value               = var.module-tag
    propagate_at_launch = true
  }

  depends_on = [aws_lb_listener.front_end]
}

output "url" {
  value = aws_lb.lb.dns_name
}

output "raw_bucket" {
  value = aws_s3_bucket.raw.bucket
}

output "finished_bucket" {
  value = aws_s3_bucket.finished.bucket
}