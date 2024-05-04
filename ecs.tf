# ECS Fargate Cluster
resource "aws_ecs_cluster" "sistema-maika-cluster" {
  name = "sistema-maika-cluster"
}

# ECS Fargate Task Definition for your web app
resource "aws_ecs_task_definition" "web_app" {
  family                   = "web-app"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  cpu       = 256
  memory    = 512

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn = aws_iam_role.ecs_task_role.arn

  container_definitions = file("web-app-container-definitions.json")

  lifecycle {
    ignore_changes = [
      container_definitions,
    ]
  }
}

resource "aws_security_group" "lb_sg" {
  name        = "lb_sg"
  description = "Security group for the load balancer of the Sistema Maika app"

  // Ingress rule for HTTP and HTTPS traffic
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  // Egress rule allowing all traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "web-app-sg" {
  name        = "web-app-sg"
  description = "Security group for the NextJS container of the Sistema Maika app"

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    security_groups = [aws_security_group.lb_sg.id]
  }

  // Egress rule allowing all traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "sistema-maika-lb" {
  name               = "sistema-maika-lb"
  internal           = false
  load_balancer_type = "application"
  ip_address_type    = "ipv4"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = ["subnet-063dd0754a0162cc2", "subnet-0ca0f0fff2624e5da", "subnet-09404e256576ad2a2"]

  tags = {
    Environment = "production"
  }
}

resource "aws_lb_target_group" "lb-target-group" {
  name     = "lb-target-group"
  target_type = "ip"
  ip_address_type = "ipv4"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = "vpc-0d4b77ec628e69134"
}

resource "aws_lb_listener" "lb-listener" {
  load_balancer_arn = aws_lb.sistema-maika-lb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "arn:aws:acm:sa-east-1:331756077753:certificate/1fa5c704-ce3b-413a-95c8-8904fea473cc"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb-target-group.arn
  }
}

resource "aws_ecs_service" "web_app" {
  name            = "web-app"
  cluster         = aws_ecs_cluster.sistema-maika-cluster.id
  task_definition = aws_ecs_task_definition.web_app.arn
  launch_type     = "FARGATE"
  desired_count   = 0

  load_balancer {
    target_group_arn = aws_lb_target_group.lb-target-group.arn
    container_name   = "web-app"
    container_port   = 3000
  }

  network_configuration {
    subnets = ["subnet-063dd0754a0162cc2", "subnet-0ca0f0fff2624e5da", "subnet-09404e256576ad2a2"]
    security_groups = [aws_security_group.web-app-sg.id]
    assign_public_ip = true
  }
}