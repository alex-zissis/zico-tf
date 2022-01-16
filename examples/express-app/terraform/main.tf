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
    key    = "micro/express-app/state.tfstate"
    region = "ap-southeast-2"
  }
}

provider "aws" {
  profile = "tf"
  region  = "ap-southeast-2"
}

data "terraform_remote_state" "zico_dev_main_tf" {
  backend = "s3"
  config = {
    bucket = "zico-dev-tf-backend"
    key    = "state"
    region = "ap-southeast-2"
  }
}

module "express_app" {
  source = "../../../modules/container-application"

  application_name           = "express-app"
  application_dns_name       = "example.api.zico.dev"
  application_hostnames      = ["example.api.zico.dev"]
  alb_listener_rule_priority = 155
  ecs_task_envrionment_variables = [{
    name  = "DOG",
    value = "royal"
  }]
  ecs_task_secrets = [{
    name      = "MY_PASS",
    valueFrom = "arn:aws:ssm:ap-southeast-2:921344595439:parameter/zico/micro/express-app/my-pass"
  }]
}
