
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


resource "aws_ecs_task_definition" "pro_golf_scores_api_td" {
  family             = "pro-golf-scores-api"
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
          name      = "SPORTRADAR_API_KEY"
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

resource "aws_ecr_repository" "pro_golf_scores_api" {
  name                 = "pro-golf-scores-api"
  image_tag_mutability = "MUTABLE"
}


resource "aws_ecs_service" "pro_golf_scores_api" {
  name                               = "pro-golf-scores-api"
  cluster                            = aws_ecs_cluster.ecs_cluster_main.id
  task_definition                    = aws_ecs_task_definition.pro_golf_scores_api_td.arn
  desired_count                      = 1
  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 100
  iam_role                           = aws_iam_role.ecs_agent.arn
  force_new_deployment               = true

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