terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.75"
    }
  }

  required_version = "~> 1.9.8"
}

provider "aws" {
  region  = "us-east-1"
  profile = "admin-1"

  assume_role {
    role_arn = "arn:aws:iam::590184057477:role/yicun-iac"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"

  name                 = "main-vpc"
  cidr                 = "10.0.0.0/16"
  azs                  = data.aws_availability_zones.available.names
  private_subnets      = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets       = ["10.0.3.0/24", "10.0.4.0/24"]
}

resource "aws_security_group" "rds-proxy-sg" {
  name        = "rds-proxy-sg"
  vpc_id      = module.vpc.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "db-proxy-sg-ingress-rule" {
  from_port       = 3306
  to_port         = 3306
  ip_protocol     = "tcp"
  cidr_ipv4       = "0.0.0.0/0"
  security_group_id = aws_security_group.rds-proxy-sg.id
}

resource "aws_vpc_security_group_egress_rule" "db-proxy-sg-egress-rule" {
  from_port       = 3306
  to_port         = 3306
  ip_protocol     = "tcp"
  cidr_ipv4       = "0.0.0.0/0"
  security_group_id = aws_security_group.rds-proxy-sg.id
}

resource "aws_db_subnet_group" "main" {
  name       = "main"
  subnet_ids = module.vpc.private_subnets
}

resource "aws_rds_cluster" "example" {
  cluster_identifier      = "example-cluster"
  engine                  = "aurora-mysql"
  engine_version          = "8.0.mysql_aurora.3.08.0"
  master_username         = "myusername"
  master_password         = "password123"
  database_name           = "exampledb"
  backup_retention_period = 5
  preferred_backup_window = "07:00-09:00"
  skip_final_snapshot     = true
  vpc_security_group_ids  = [aws_security_group.rds-proxy-sg.id]
  db_subnet_group_name    = aws_db_subnet_group.main.name
}

resource "aws_secretsmanager_secret" "db-credentials" {
  name_prefix = "db-credentials-"
}

resource "aws_secretsmanager_secret_version" "db-credentials-version" {
  secret_id     = aws_secretsmanager_secret.db-credentials.id
  secret_string = jsonencode({
    username = aws_rds_cluster.example.master_username
    password = aws_rds_cluster.example.master_password
  })
}

resource "aws_iam_role" "rds-proxy-role" {
  name = "rds-proxy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "rds.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "rds-proxy-policy" {
  name        = "rds-proxy-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
        ]
        Resource = [
          "${aws_secretsmanager_secret_version.db-credentials-version.arn}",
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach-proxy-policy" {
  role       = aws_iam_role.rds-proxy-role.name
  policy_arn = aws_iam_policy.rds-proxy-policy.arn
}

resource "aws_db_proxy" "example" {
  name                   = "example-proxy"
  debug_logging          = false
  engine_family          = "MYSQL"
  idle_client_timeout    = 1800
  require_tls            = true
  role_arn               = aws_iam_role.rds-proxy-role.arn
  vpc_security_group_ids = [aws_security_group.rds-proxy-sg.id]
  vpc_subnet_ids         = module.vpc.private_subnets

  auth {
    auth_scheme  = "SECRETS"
    secret_arn   = aws_secretsmanager_secret.db-credentials.arn
    iam_auth     = "DISABLED"
  }
}

resource "aws_db_proxy_default_target_group" "example" {
  db_proxy_name = aws_db_proxy.example.name

  connection_pool_config {
    connection_borrow_timeout    = 120
    init_query                   = "SET x=1, y=2"
    max_connections_percent      = 100
    max_idle_connections_percent = 50
    session_pinning_filters      = ["EXCLUDE_VARIABLE_SETS"]
  }
}

resource "aws_db_proxy_target" "example" {
  db_cluster_identifier = aws_rds_cluster.example.cluster_identifier
  db_proxy_name          = aws_db_proxy.example.name
  target_group_name      = aws_db_proxy_default_target_group.example.name
}
