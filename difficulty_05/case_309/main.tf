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
  region = "us-east-1"
  profile = "admin-1"

  assume_role {
    role_arn = "arn:aws:iam::590184057477:role/yicun-iac"
  }
}

data "aws_ami" "amzn-linux-2023-ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

resource "aws_key_pair" "cloud_desktop" {
  public_key = file("./supplement/key.pub")
}

resource "aws_instance" "cloud_desktop" {
  ami           = data.aws_ami.amzn-linux-2023-ami.id
  instance_type = "t2.micro"
  key_name      = aws_key_pair.cloud_desktop.key_name
}

resource "aws_backup_plan" "cloud_desktop_backup" {
  name = "cloud_desktop_backup_plan"
  rule {
    rule_name         = "cloud_desktop_backup_rule"
    target_vault_name = aws_backup_vault.valut.name
    schedule          = "cron(0 0 * * ? *)"

    lifecycle {
      delete_after = 7
    }
  }

  advanced_backup_setting {
    backup_options = {
      WindowsVSS = "enabled"
    }
    resource_type = "EC2"
  }
}

resource "aws_backup_vault" "valut" {
  name = "cloud_desktop_backup_valut"
}

resource "aws_backup_selection" "backup_ec2" {
  iam_role_arn = aws_iam_role.backup.arn

  name    = "backup_ec2"
  plan_id = aws_backup_plan.cloud_desktop_backup.id

  resources = [
    aws_instance.cloud_desktop.arn,
  ]
}

data "aws_iam_policy_document" "backup_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["backup.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "backup" {
  name               = "backup"
  assume_role_policy = data.aws_iam_policy_document.backup_assume_role.json
}

resource "aws_iam_role_policy_attachment" "backup" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
  role       = aws_iam_role.backup.name
}