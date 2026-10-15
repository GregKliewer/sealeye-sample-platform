locals {
  # From staging up, an environment is held to production's rules (see the README).
  upper_stage = contains(["staging", "perf", "prod"], var.stage)
  full_name   = "${var.name}-${var.stage}"
  tags = merge(var.tags, {
    "juniper:app"     = var.name
    "juniper:stage"   = var.stage
    "juniper:module"  = "container-service"
    "juniper:library" = "platform-library"
  })
}

resource "aws_cloudwatch_log_group" "svc" {
  name              = "/juniper/${local.full_name}"
  retention_in_days = local.upper_stage ? 365 : 7
  tags              = local.tags
}

resource "aws_ecs_task_definition" "svc" {
  family                   = local.full_name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = local.upper_stage ? "1024" : "256"
  memory                   = local.upper_stage ? "2048" : "512"
  execution_role_arn       = var.execution_role_arn
  tags                     = local.tags

  container_definitions = jsonencode([
    {
      name         = var.name
      image        = var.image
      essential    = true
      portMappings = [{ containerPort = var.container_port }]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.svc.name
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = var.name
        }
      }
    }
  ])
}

data "aws_region" "current" {}

resource "aws_ecs_service" "svc" {
  name            = local.full_name
  cluster         = var.cluster_arn
  task_definition = aws_ecs_task_definition.svc.arn
  desired_count   = local.upper_stage ? 3 : 1
  launch_type     = "FARGATE"
  tags            = local.tags

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = var.security_group_ids
    assign_public_ip = false
  }
}
