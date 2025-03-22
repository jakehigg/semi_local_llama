provider "aws" {
  region = var.aws_region # Replace with your desired region
}


resource "aws_iam_role" "ollama_role" {
  name = "ollama-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
  tags = {
    Application = "ollama"
  }
}


# Role Policy to allow SSM SessionManager
resource "aws_iam_role_policy" "ollama_role_policy" {
  name = "allow_ssm"
  role = aws_iam_role.ollama_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ssm:UpdateInstanceInformation",
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}


# Only allow Outbound
resource "aws_security_group" "ollama-out" {
  vpc_id = var.ollama_instance_vpc

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Application = "ollama"
  }
}


resource "aws_iam_instance_profile" "ollama_profile" {
  name = "ollama-profile"
  role = aws_iam_role.ollama_role.name
  tags = {
    Application = "ollama"
  }
}


resource "aws_instance" "ollama" {
  ami           = var.ollama_instance_ami
  instance_type = var.ollama_instance_type

  subnet_id                   = var.ollama_instance_subnet
  vpc_security_group_ids      = ["${aws_security_group.ollama-out.id}"]
  associate_public_ip_address = true
  # instance_market_options {
  #   market_type = "spot"
  #   spot_options {
  #     max_price = var.ollama_instance_spot_price
  #   }
  # }


  root_block_device {
    volume_size = var.ollama_volume_size
    volume_type = var.ollama_volume_type
  }
  iam_instance_profile = aws_iam_instance_profile.ollama_profile.name
  user_data            = <<-EOF
                #!/bin/bash
                sudo curl -fsSL https://ollama.com/install.sh | sh
                sudo service ollama start
                sleep 2
                ${var.ollama_pull_model != null ? "sudo ollama pull ${var.ollama_pull_model}" : ""}
                EOF

  tags = {
    Application = "ollama"
  }
}


resource "aws_cloudwatch_metric_alarm" "ollama-idle" {
  alarm_name                = "ollama-idle"
  comparison_operator       = "LessThanOrEqualToThreshold"
  evaluation_periods        = (var.instance_idle_minutes / 5)
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = 300
  statistic                 = "Average"
  threshold                 = 30
  alarm_description         = "This Alarm monitors the cpu state of the Ollama instance"
  insufficient_data_actions = []

  dimensions = {
    InstanceId = aws_instance.ollama.id
  }

  alarm_actions = compact([
    "arn:aws:automate:${var.aws_region}:ec2:stop",
    var.sns_notification_arn
  ])

  tags = {
    Application = "ollama"
  }
}