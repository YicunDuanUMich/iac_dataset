# Define the provider block for AWS
provider "aws" {
  region = "us-east-2" # Set your desired AWS region
}

resource "aws_vpc" "_" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  tags = merge(var.tags, {
    "Name" = "${var.name_prefix}-vpc"
  })
}

resource "aws_subnet" "public" {
  count             = var.subnet_count.public
  vpc_id            = aws_vpc._.id
  cidr_block        = var.public_subnet_cidr_blocks[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = merge(var.tags, {
    "Name" = "${var.name_prefix}-public-subnet-${count.index}"
  })
}

resource "aws_security_group" "master" {
  name        = "master"
  description = "Allow incoming connections"
  vpc_id      = aws_vpc._.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow incoming SSH connections (Linux)"
  }
  ingress {
    from_port       = 5678
    to_port         = 5678
    protocol        = "tcp"
    security_groups = [aws_security_group.api.id]
    description     = "Allow incoming HTTP connections"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(var.tags, {
    "Name" = "${var.name_prefix}-sg"
  })
}

resource "aws_security_group" "worker" {
  name        = "worker_server_sg"
  description = "Allow incoming connections"
  vpc_id      = aws_vpc._.id
  ingress {
    from_port       = 1234
    to_port         = 1234
    protocol        = "tcp"
    security_groups = [aws_security_group.master.id, aws_security_group.api.id]
    description     = "Allow incoming HTTP connections"
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow incoming SSH connections (Linux)"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(var.tags, {
    "Name" = "${var.name_prefix}-worker-sg"
  })
}

resource "aws_security_group" "alert" {
  name        = "alert_server_sg"
  description = "Allow incoming connections"
  vpc_id      = aws_vpc._.id
  ingress {
    from_port       = 50052
    to_port         = 50053
    protocol        = "tcp"
    security_groups = [aws_security_group.worker.id]
    description     = "Allow incoming HTTP connections"
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow incoming SSH connections (Linux)"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(var.tags, {
    "Name" = "${var.name_prefix}-alert-sg"
  })
}

resource "aws_security_group" "api" {
  name        = "api"
  description = "Allow incoming connections"
  vpc_id      = aws_vpc._.id
  ingress {
    from_port   = 12345
    to_port     = 12345
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow incoming HTTP connections"
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow incoming SSH connections (Linux)"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(var.tags, {
    "Name" = "${var.name_prefix}-sg"
  })
}

resource "aws_security_group" "standalone" {
  name        = "standalone"
  description = "Allow incoming connections"
  vpc_id      = aws_vpc._.id
  ingress {
    from_port   = 12345
    to_port     = 12345
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow incoming HTTP connections"
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow incoming SSH connections (Linux)"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(var.tags, {
    "Name" = "${var.name_prefix}-sg"
  })
}

resource "aws_security_group" "database_sg" {
  name        = "dolphinscheduler-database"
  vpc_id      = aws_vpc._.id
  description = "Allow all inbound for Postgres"
  ingress {
    from_port = 5432
    to_port   = 5432
    protocol  = "tcp"
    security_groups = [
      aws_security_group.master.id,
      aws_security_group.worker.id,
      aws_security_group.alert.id,
      aws_security_group.api.id,
      aws_security_group.standalone.id
    ]
  }
}


resource "aws_db_subnet_group" "database_subnet_group" {
  name       = "dolphinscheduler-database_subnet_group"
  subnet_ids = [for subnet in aws_subnet.private : subnet.id]
}

resource "aws_subnet" "private" {
  count             = var.subnet_count.private
  vpc_id            = aws_vpc._.id
  cidr_block        = var.private_subnet_cidr_blocks[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = merge(var.tags, {
    "Name" = "${var.name_prefix}-private-subnet-${count.index}"
  })
}

resource "aws_db_instance" "database" {
  identifier             = "dolphinscheduler"
  db_name                = "dolphinscheduler"
  instance_class         = var.db_instance_class
  allocated_storage      = 5
  engine                 = "postgres"
  engine_version         = "14.5"
  skip_final_snapshot    = true
  db_subnet_group_name   = aws_db_subnet_group.database_subnet_group.id
  publicly_accessible    = true
  vpc_security_group_ids = [aws_security_group.database_sg.id]
  username               = var.db_username
  password               = var.db_password
}

variable "db_password" {
  description = "Database password"
  type        = string
  default = "random-password"
}
variable "db_username" {
  description = "Database username"
  type        = string
  default     = "dolphinscheduler"
}
variable "db_instance_class" {
  description = "Database instance class"
  default     = "db.t3.micro"
}

variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "cn-north-1"
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources"
  default = {
    "Deployment" = "Test"
  }
}

variable "name_prefix" {
  type        = string
  description = "Name prefix for all resources"
  default     = "dolphinscheduler"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR for the VPC"
  default     = "10.0.0.0/16"
}

data "aws_availability_zones" "available" {
  state = "available"
}

variable "subnet_count" {
  description = "Number of subnets"
  type        = map(number)
  default = {
    public  = 1,
    private = 2
  }
}

variable "public_subnet_cidr_blocks" {
  type        = list(string)
  description = "CIDR blocks for the public subnets"
  default = [
    "10.0.1.0/24",
    "10.0.2.0/24",
    "10.0.3.0/24",
    "10.0.4.0/24"
  ]
}

variable "private_subnet_cidr_blocks" {
  description = "Available CIDR blocks for private subnets"
  type        = list(string)
  default = [
    "10.0.101.0/24",
    "10.0.102.0/24",
    "10.0.103.0/24",
    "10.0.104.0/24",
  ]
}