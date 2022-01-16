locals {
  home_ip = "203.129.21.208/32"
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

  tags = {
    Name = "ecs-sg"
  }
}

resource "aws_security_group_rule" "ssh_from_home" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [local.home_ip]
  security_group_id = aws_security_group.ecs_sg.id
}

resource "aws_security_group_rule" "ecs_egress_to_internet" {
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ecs_sg.id
}

resource "aws_security_group_rule" "ecs_epheremiral_to_alb" {
  type                     = "ingress"
  from_port                = 32768
  to_port                  = 60999
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb_sg.id
  security_group_id        = aws_security_group.ecs_sg.id
}

resource "aws_security_group" "alb_sg" {
  vpc_id = aws_vpc.apse_2_main.id

  tags = {
    Name = "alb-sg"
  }
}

resource "aws_security_group_rule" "http_from_internet" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb_sg.id
}

resource "aws_security_group_rule" "https_from_internet" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb_sg.id
}


resource "aws_security_group_rule" "egress_to_internet" {
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb_sg.id
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

  tags = {
    Name = "apse2-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.apse_2_main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }

  tags = {
    Name = "apse2-rt"
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