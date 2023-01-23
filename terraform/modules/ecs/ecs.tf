##########################################################
########################## SG ############################
##########################################################
# Security group for service and ALB
resource "aws_security_group" "ecs_security_group" {
  name        = "acme-service-sg"
  description = "Service SG TODO"
  vpc_id      = var.vpc_id
  ingress {
    from_port = "0"
    to_port   = "0"
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port = "0"
    to_port   = "0"
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

##########################################################
########################## S3 ############################
########################################################## 
resource "aws_s3_bucket" "bucket" {
  bucket = "nginx-acme-bucket"
}

##########################################################
########################## IAM ###########################
##########################################################
data "aws_iam_policy_document" "ecs_task_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "nginx_task_execution_role" {
  name               = "nginx-task-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json
}

resource "aws_iam_policy" "ecs_task_execution_role" {
  name        = "nginx_service_policy"
  path        = "/"
  description = "Acme Nginx Service Policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:ListBucket",
        ]
        Effect   = "Allow"
        Resource = aws_s3_bucket.bucket.arn
      },
      {
        Action = [
          "s3:*Object",
        ]
        Effect   = "Allow"
        Resource = "${aws_s3_bucket.bucket.arn}/*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role" {
  role       = aws_iam_role.nginx_task_execution_role.name
  policy_arn = aws_iam_policy.ecs_task_execution_role.arn
}

##########################################################
########################## ECS ###########################
##########################################################
resource "aws_ecs_cluster" "cluster" {
  name = "nginx-cluster"
}

resource "aws_ecs_task_definition" "nginx" {
  family = "nginx"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.nginx_task_execution_role.arn
  container_definitions = <<DEFINITION
[
  {
    "name": "nginx",
    "image": "docker.io/nginx:latest",
    "portMappings": [
      {
        "containerPort": 80
      }
    ],
    "memory": 512,
    "cpu": 256
  }
]
DEFINITION
}

resource "aws_ecs_service" "nginx" {
  name            = "nginx"
  launch_type     = "FARGATE"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.nginx.arn
  desired_count   = 1
  network_configuration {
    subnets          = var.private_subnets
    security_groups  = [aws_security_group.ecs_security_group.id]
    assign_public_ip = false
  }
  load_balancer {
    target_group_arn = aws_alb_target_group.nginx.arn
    container_name   = "nginx"
    container_port   = 80
  }
}

##########################################################
########################## ALB ###########################
##########################################################
resource "aws_alb" "nginx" {
  name = "nginx-alb"
  internal = false
  security_groups = [aws_security_group.ecs_security_group.id]
  subnets = var.public_subnets
  load_balancer_type = "application"
}

resource "aws_alb_target_group" "nginx" {
  name = "nginx-tg"
  port = 80
  protocol = "HTTP"
  vpc_id = var.vpc_id
  target_type = "ip"

  health_check {
    enabled = true
    path    = "/"
  }
}

resource "aws_alb_listener" "nginx" {
  load_balancer_arn = aws_alb.nginx.arn
  port = "80"
  protocol = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_alb_target_group.nginx.arn
  }
}
