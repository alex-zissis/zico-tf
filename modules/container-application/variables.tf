variable "application_name" {
  description = "The name of the application. Must be unique within your cloud instance. Resources like ECS Service Name, CloudWatch Log Groups etc. will use this value."
  type        = string
}

variable "region" {
  description = "AWS Region to provision resources in."
  default     = "ap-southeast-2"
  type        = string
}

variable "vpc_id" {
  type        = string
  description = "ID of the VPC to provision all resources in."
  default     = "vpc-02c26163b069b22ae"
}

variable "ecs_cluster_id" {
  type        = string
  description = "ID of the ECS cluster to provision the Service and Tasks in."
  default     = "arn:aws:ecs:ap-southeast-2:921344595439:cluster/ecs-cluster-main"
}

variable "ecs_task_cpu_units" {
  description = "CPU units to provision for ECS task."
  type        = number
  default     = 64
}

variable "ecs_task_memory_reservation" {
  description = "RAM (in MB) to provision for the ECS task."
  type        = number
  default     = 128
}

variable "ecs_task_container_port" {
  description = "Port that the Docker container of the task exposes."
  type        = number
  default     = 3000
}

variable "ecs_service_desired_tasks" {
  description = "Amount of tasks to run in the ECS Service."
  type        = number
  default     = 1
}

variable "ecs_servce_deployment_minimum_healthy_percent" {
  description = "The minimum amount of tasks that can be running at once during a deploy. Expressed as a percentage of the ecs_service_desired_tasks."
  type        = number
  default     = 100
}

variable "ecs_service_maximum_healthy_percentage" {
  description = "The maximum amount of tasks that can be running at once during a deploy. Expressed as a percentage of the ecs_service_desired_tasks."
  type        = number
  default     = 200
}

variable "alb_health_check_route" {
  description = "Realtive route on the service to peform a healthcheck on. This route needs to return a 200."
  default     = "/health"
  type        = string
}

variable "ecs_service_execution_role_arn" {
  description = "ARN of the IAM role used to execute the Service & Task Definition."
  type        = string
  default     = "arn:aws:iam::921344595439:role/ecs-agent"
}

variable "alb_listener_arn" {
  description = "ARN of the ALB to add the listener too."
  type        = string
  default     = "arn:aws:elasticloadbalancing:ap-southeast-2:921344595439:listener/app/zico-dev-alb/95e8654c9f9bb1cc/4dbbf91155efcb40"
}

variable "alb_listener_rule_priority" {
  description = "Priority of the rule to apply to the ALB Listener (100-999)."
  type        = number
}

variable "application_hostnames" {
  description = "Application host names to add to the ALB Listener."
  type        = set(string)
}

variable "application_dns_name" {
  description = "Default DNS record to add to access the application."
  type        = string
}

variable "ssl_certificate_name" {
  description = "Domain name to create an SSL cert for."
  type        = string
  default     = null
}

variable "ssl_cert_alternative_names" {
  description = "Additional domain names to add to the SSL Cert."
  type        = set(string)
  default     = []
}

variable "route_53_zone_id" {
  type        = string
  description = "Route53 Zone ID where DNS records will be created. No DNS records will be created if no value is provided."
  default     = "Z02158791WBS3WE46AAY6"
}

variable "alb_zone_id" {
  description = "Zone ID of the ALB."
  type        = string
  default     = "Z1GM3OXH4ZPM65"
}

variable "alb_dns_name" {
  description = "DNS name of the ALB."
  type        = string
  default     = "zico-dev-alb-431436678.ap-southeast-2.elb.amazonaws.com"
}

variable "deployer_iam_user_policy" {
  description = "Policy to attach to the IAM user who has deployment rights to the ECR repo."
  type        = string
  default     = "arn:aws:iam::921344595439:policy/ecs-deployer"
}

variable "cloudwatch_log_retention_days" {
  description = "Number of days to retain logs in CloudWatch for."
  type        = number
  default     = 7
}

variable "ecs_task_envrionment_variables" {
  description = "Environment variables to add to the ECS tasks. For sensitive values use 'ecs_tasks_secrets'"
  type = set(object({
    name  = string
    value = string
  }))

  default = []
}

variable "ecs_task_secrets" {
  description = "Secret environment variables to add to the ECS tasks. Use valueFrom and provide an SSM Param. Don't pass values in directly."
  type = set(object({
    name      = string
    valueFrom = string
  }))
  sensitive = false

  default = []
}