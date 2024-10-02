provider "aws" {
  region = var.aws_region
}

resource "aws_key_pair" "proxy-key" {
  key_name   = "proxy-key-pair"
  public_key = file("./ssh/proxy_instance.pub")
}

resource "aws_key_pair" "apps-key" {
  key_name   = "apps-key-pair"
  public_key = file("./ssh/apps_instance.pub")
}

resource "aws_iam_role" "server_role" {
  name = "server_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

data "aws_iam_policy" "SSMFullAccess" {
  arn = "arn:aws:iam::aws:policy/AmazonSSMFullAccess"
}

resource "aws_iam_role_policy_attachment" "ssmfullaccess-role-policy-attach" {
  role       = "${aws_iam_role.server_role.name}"
  policy_arn = "${data.aws_iam_policy.SSMFullAccess.arn}"
}

resource "aws_iam_instance_profile" "server_profile" {
  name = "server_profile"
  role = aws_iam_role.server_role.name
}

resource "aws_instance" "t2_micro" {
  ami = "ami-03376b64cbb65efec"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.proxy_manager.id, aws_security_group.internal_communication.id, aws_security_group.ssh_access.id]
  root_block_device {
    volume_size = 8
    volume_type = "gp3"
  }

  iam_instance_profile = aws_iam_instance_profile.server_profile.name

  key_name = aws_key_pair.proxy-key.key_name

  tags = {
    Name = "proxy_instance"
  }

  lifecycle {
    ignore_changes = [associate_public_ip_address, security_groups, tags]
    prevent_destroy = true
  }
}

resource "aws_instance" "t3a_medium" {
  ami = "ami-0af6e9042ea5a4e3e"
  instance_type = "t3a.medium"
  associate_public_ip_address = false
  vpc_security_group_ids = [aws_security_group.proxy_manager.id, aws_security_group.internal_communication.id, aws_security_group.ssh_access.id]
  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  iam_instance_profile = aws_iam_instance_profile.server_profile.name

  key_name = aws_key_pair.apps-key.key_name

  tags = {
    Name = "apps_instance"
  }

  lifecycle {
    ignore_changes = [associate_public_ip_address, security_groups, tags]
    prevent_destroy = true
  }
}

locals {
  instance_ids = [aws_instance.t2_micro.id, aws_instance.t3a_medium.id]
}
