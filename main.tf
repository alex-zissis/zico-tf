terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 1.1.3"
}

provider "aws" {
  profile = "personal"
  region  = "ap-southeast-2"
}

resource "aws_vpc" "apse_2_main" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "apse_2_main"
  }
}

resource "aws_security_group" "ecs_sg" {
  vpc_id = aws_vpc.apse_2_main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["203.129.21.208/32"]
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_security_group" "alb_sg" {
  vpc_id = aws_vpc.apse_2_main.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_subnet" "apse_prod_2a" {
  vpc_id            = aws_vpc.apse_2_main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-southeast-2a"

  tags = {
    Name = "apse_prod_2a"
  }
}

resource "aws_subnet" "apse_prod_2b" {
  vpc_id            = aws_vpc.apse_2_main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-southeast-2b"

  tags = {
    Name = "apse_prod_2b"
  }
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.apse_2_main.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.apse_2_main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }
}

resource "aws_route_table_association" "aspe_prod_2a_rta" {
  subnet_id      = aws_subnet.apse_prod_2a.id
  route_table_id = aws_route_table.public.id
}


resource "aws_route_table_association" "aspe_prod_2b_rta" {
  subnet_id      = aws_subnet.apse_prod_2b.id
  route_table_id = aws_route_table.public.id
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
  role       = aws_iam_role.ecs_agent.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_instance_profile" "ecs_agent" {
  name = "ecs-agent"
  role = aws_iam_role.ecs_agent.name
}

resource "aws_launch_configuration" "ecs_launch_config" {
  image_id             = "ami-0ecac5dc97c76f51d"
  iam_instance_profile = aws_iam_instance_profile.ecs_agent.name
  security_groups      = [aws_security_group.ecs_sg.id]
  user_data            = "#!/bin/bash\necho ECS_CLUSTER=ecs-cluster-main >> /etc/ecs/ecs.config"
  instance_type        = "t2.micro"
  key_name             = aws_key_pair.alex_mbp.key_name

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "zico_dev_ecs_asg" {
  name                 = "zico_dev_ecs_asg"
  vpc_zone_identifier  = [aws_subnet.apse_prod_2a.id]
  launch_configuration = aws_launch_configuration.ecs_launch_config.name
  target_group_arns    = [aws_alb_target_group.pro_golf_scores_api_alb_tg.arn]

  desired_capacity          = 1
  min_size                  = 1
  max_size                  = 10
  health_check_grace_period = 300
  health_check_type         = "EC2"

  lifecycle {
    create_before_destroy = true
  }
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

# resource "aws_lb_listener" "zico_dev_listner" {
#   load_balancer_arn = aws_lb.zico_dev.arn

#   protocol = "HTTP"
#   port     = 80

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_alb_target_group.pro_golf_scores_api_alb_tg.arn
#   }
# }

resource "aws_lb_listener_rule" "golf_scores_listener" {
  listener_arn = aws_lb_listener.listener.arn
  priority     = 101

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.pro_golf_scores_api_alb_tg.arn
  }

  condition {
    host_header {
      values = ["*.api.zico.dev"]
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

resource "aws_ecr_repository" "pro_golf_scores_api" {
  name                 = "pro-golf-scores-api"
  image_tag_mutability = "MUTABLE"
}

resource "aws_ecs_task_definition" "pro_golf_scores_api_td" {
  family = "pro-golf-scores-api"
  execution_role_arn = aws_iam_role.ecs_agent.arn
  container_definitions = jsonencode([
    {
      name      = "pro-golf-scores-api"
      image     = "${aws_ecr_repository.pro_golf_scores_api.repository_url}:latest"
      cpu       = 64
      memory    = 128
      essential = true
      secrets = [
          {
            name = "SPORTRADAR_API_KEY"
            valueFrom = "arn:aws:ssm:ap-southeast-2:921344595439:parameter/sportradar_api_key" 
        }
      ]
      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
        }
      ]
    }
  ])
}

resource "aws_kms_key" "logging_key" {
  description             = "Key for logging"
  deletion_window_in_days = 7
}

resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name = "ecs-log-group"
}

resource "aws_ecs_cluster" "ecs_cluster_main" {
  name = "ecs-cluster-main"

  configuration {
    execute_command_configuration {
      kms_key_id = aws_kms_key.logging_key.arn
      logging    = "OVERRIDE"

      log_configuration {
        cloud_watch_encryption_enabled = true
        cloud_watch_log_group_name     = aws_cloudwatch_log_group.ecs_log_group.name
      }
    }
  }
}

resource "aws_ecs_service" "pro_golf_scores_api" {
  name                 = "pro-golf-scores-api"
  cluster              = aws_ecs_cluster.ecs_cluster_main.id
  task_definition      = aws_ecs_task_definition.pro_golf_scores_api_td.arn
  desired_count        = 1
  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent = 100
  iam_role             = aws_iam_role.ecs_agent.arn
  force_new_deployment = true

  ordered_placement_strategy {
    type  = "binpack"
    field = "cpu"
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.pro_golf_scores_api_alb_tg.arn
    container_name   = "pro-golf-scores-api"
    container_port   = 3000
  }
}

output "ecr_repository_pro_golf_scores_api_endpoint" {
  value = aws_ecr_repository.pro_golf_scores_api.repository_url
}

output "zico_dev_alb_dns_name" {
  value = aws_lb.zico_dev.dns_name
}