terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 1.1.3"

  backend "s3" {
    bucket = "zico-dev-tf-backend"
    key    = "state"
    region = "ap-southeast-2"
  }
}

provider "aws" {
  region  = "ap-southeast-2"
}

resource "aws_lb" "zico_dev" {
  name               = "zico-dev-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.apse_prod_2a.id, aws_subnet.apse_prod_2b.id]

  enable_deletion_protection = true
}

resource "aws_alb_target_group" "pro_golf_scores_api_alb_tg" {
  name        = "pgs-api-alb-tg-20221001"
  port        = 3000
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.apse_2_main.id

  health_check {
    path    = "/health"
    matcher = "200"
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [aws_lb.zico_dev]
}

resource "aws_key_pair" "alex_mbp" {
  key_name   = "alex-mbp-key"
  public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBPsnmU6KWQjH93IQBpObVDCpb1+H+2leyYBSBSSP8FF alex_z9@outlook.com"
}

resource "aws_iam_role" "ecs_agent" {
  name               = "ecs-agent"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": ["ecs.amazonaws.com", "ec2.amazonaws.com", "ecs-tasks.amazonaws.com"]
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs_agent" {
  role = aws_iam_role.ecs_agent.name
  # todo: fix
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_instance_profile" "ecs_agent" {
  name = "ecs-agent"
  role = aws_iam_role.ecs_agent.name
}

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.zico_dev.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_acm_certificate" "api_cert" {
  domain_name       = "*.api.zico.dev"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_zone" "primary" {
  name = "zico.dev"
}

resource "aws_route53_record" "api_cert_records" {
  for_each = {
    for dvo in aws_acm_certificate.api_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.primary.zone_id
}

resource "aws_acm_certificate_validation" "api_cert_validation" {
  certificate_arn         = aws_acm_certificate.api_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.api_cert_records : record.fqdn]
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.zico_dev.arn # Referencing our load balancer
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.api_cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.pro_golf_scores_api_alb_tg.arn
  }
}

resource "aws_lb_listener_certificate" "api_listner_cert" {
  listener_arn    = aws_lb_listener.listener.arn
  certificate_arn = aws_acm_certificate.api_cert.arn
}

resource "aws_lb_listener_rule" "golf_scores_listener" {
  listener_arn = aws_lb_listener.listener.arn
  priority     = 101

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.pro_golf_scores_api_alb_tg.arn
  }

  condition {
    host_header {
      values = ["golf.api.zico.dev"]
    }
  }
}

resource "aws_route53_record" "golf-scores-api-record" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "golf.api.zico.dev"
  type    = "A"

  alias {
    name                   = aws_lb.zico_dev.dns_name
    zone_id                = aws_lb.zico_dev.zone_id
    evaluate_target_health = true
  }
}

output "ecr_repository_pro_golf_scores_api_endpoint" {
  value = aws_ecr_repository.pro_golf_scores_api.repository_url
}

output "zico_dev_alb_dns_name" {
  value = aws_lb.zico_dev.dns_name
}

output "zico_dev_alb_zone_id" {
  value = aws_lb.zico_dev.zone_id
}

output "ecs_agent_iam_role_arn" {
  value = aws_iam_role.ecs_agent.arn
}

output "main_vpc_id" {
  value = aws_vpc.apse_2_main.id
}

output "main_ecs_cluster_id" {
  value = aws_ecs_cluster.ecs_cluster_main.id
}

output "zico_dev_alb_https_listener_arn" {
  value = aws_lb_listener.listener.arn
}

output "zico_dev_r53_zone_id" {
  value = aws_route53_zone.primary.zone_id
}