data "aws_iam_policy_document" "assume_ec2" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# Control plane: publishes the kubeadm join command for the worker to read.
resource "aws_iam_role" "control_plane" {
  name               = "${var.project_name}-control-plane"
  assume_role_policy = data.aws_iam_policy_document.assume_ec2.json

  tags = {
    Project = var.project_name
  }
}

data "aws_iam_policy_document" "control_plane_ssm" {
  statement {
    actions   = ["ssm:PutParameter"]
    resources = ["arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/${var.project_name}/join-command"]
  }
}

resource "aws_iam_role_policy" "control_plane_ssm" {
  name   = "${var.project_name}-control-plane-ssm"
  role   = aws_iam_role.control_plane.id
  policy = data.aws_iam_policy_document.control_plane_ssm.json
}

resource "aws_iam_instance_profile" "control_plane" {
  name = "${var.project_name}-control-plane"
  role = aws_iam_role.control_plane.name
}

# Worker: reads the kubeadm join command published by the control plane.
resource "aws_iam_role" "worker" {
  name               = "${var.project_name}-worker"
  assume_role_policy = data.aws_iam_policy_document.assume_ec2.json

  tags = {
    Project = var.project_name
  }
}

data "aws_iam_policy_document" "worker_ssm" {
  statement {
    actions   = ["ssm:GetParameter"]
    resources = ["arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/${var.project_name}/join-command"]
  }
}

resource "aws_iam_role_policy" "worker_ssm" {
  name   = "${var.project_name}-worker-ssm"
  role   = aws_iam_role.worker.id
  policy = data.aws_iam_policy_document.worker_ssm.json
}

resource "aws_iam_instance_profile" "worker" {
  name = "${var.project_name}-worker"
  role = aws_iam_role.worker.name
}
