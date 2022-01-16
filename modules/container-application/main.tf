resource "aws_ecr_repository" "ecr_repo" {
  name                 = var.application_name
  image_tag_mutability = "MUTABLE"
}

resource "aws_cloudwatch_log_group" "log_group" {
  name              = "/zico/micro/${var.application_name}"
  retention_in_days = var.cloudwatch_log_retention_days
}


resource "aws_ecs_task_definition" "task_def" {
  family             = var.application_name
  execution_role_arn = var.ecs_service_execution_role_arn
  container_definitions = jsonencode([
    {
      name        = var.application_name
      image       = "${aws_ecr_repository.ecr_repo.repository_url}:latest"
      cpu         = var.ecs_task_cpu_units
      memory      = var.ecs_task_memory_reservation
      essential   = true
      secrets     = var.ecs_task_secrets
      environment = var.ecs_task_envrionment_variables

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/zico/micro/${var.application_name}",
          awslogs-region        = var.region,
          awslogs-stream-prefix = "logs"
        }
      }
      portMappings = [
        {
          containerPort = var.ecs_task_container_port
          hostPort      = 0
        }
      ]
    }
  ])
}

resource "time_static" "now" {}

resource "aws_alb_target_group" "target_group" {
  name        = "${var.application_name}-alb-tg-${time_static.now.unix}"
  port        = var.ecs_task_container_port
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = var.vpc_id

  health_check {
    path    = var.alb_health_check_route
    matcher = "200"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_ecs_service" "ecs_service" {
  name                               = var.application_name
  cluster                            = var.ecs_cluster_id
  task_definition                    = aws_ecs_task_definition.task_def.arn
  desired_count                      = var.ecs_service_desired_tasks
  deployment_minimum_healthy_percent = var.ecs_servce_deployment_minimum_healthy_percent
  deployment_maximum_percent         = var.ecs_service_maximum_healthy_percentage
  iam_role                           = var.ecs_service_execution_role_arn
  force_new_deployment               = true

  ordered_placement_strategy {
    type  = "binpack"
    field = "cpu"
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.target_group.arn
    container_name   = var.application_name
    container_port   = var.ecs_task_container_port
  }
}

resource "aws_lb_listener_rule" "alb_listener_rule" {
  listener_arn = var.alb_listener_arn
  priority     = var.alb_listener_rule_priority

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.target_group.arn

  }

  condition {
    host_header {
      values = var.application_hostnames
    }
  }
}

resource "aws_acm_certificate" "ssl_cert" {
  count                     = var.ssl_certificate_name != null ? 1 : 0
  domain_name               = var.ssl_certificate_name
  validation_method         = "DNS"
  subject_alternative_names = var.ssl_cert_alternative_names

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_records" {
  for_each = {
    for cert in aws_acm_certificate.ssl_cert : cert.name => {
      for dvo in cert.domain_validation_options : dvo.domain_name => {
        name   = dvo.resource_record_name
        record = dvo.resource_record_value
        type   = dvo.resource_record_type
      }
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.route_53_zone_id
}

resource "aws_acm_certificate_validation" "cert_validation" {
  count                   = var.ssl_certificate_name != null ? 1 : 0
  certificate_arn         = aws_acm_certificate.ssl_cert[count.index].arn
  validation_record_fqdns = [for record in aws_route53_record.cert_records : record.fqdn]
}

resource "aws_lb_listener_certificate" "alb_listener_cert" {
  count           = var.ssl_certificate_name != null ? 1 : 0
  listener_arn    = var.alb_listener_arn
  certificate_arn = aws_acm_certificate.ssl_cert[count.index].arn
}


resource "aws_route53_record" "application_alias_record" {
  count   = var.route_53_zone_id != null ? 1 : 0
  zone_id = var.route_53_zone_id
  name    = var.application_dns_name
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}

resource "aws_iam_user" "deployer_user" {
  name = "${var.application_name}-deployer"
}

resource "aws_iam_access_key" "deployer_key" {
  user = aws_iam_user.deployer_user.name
}

resource "aws_iam_user_policy_attachment" "deployer_user_attachment" {
  user       = aws_iam_user.deployer_user.name
  policy_arn = var.deployer_iam_user_policy
}
