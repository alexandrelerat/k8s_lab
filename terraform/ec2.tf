resource "aws_instance" "control_plane" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.control_plane_instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.nodes.id]
  key_name                    = aws_key_pair.this.key_name
  iam_instance_profile        = aws_iam_instance_profile.control_plane.name
  private_ip                  = local.cp_private_ip
  associate_public_ip_address = true

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    encrypted             = true
    delete_on_termination = true
  }

  user_data = templatefile("${path.module}/templates/control-plane-init.sh.tftpl", {
    kubernetes_version = var.kubernetes_version
    region             = var.region
    project_name       = var.project_name
    cp_private_ip      = local.cp_private_ip
  })

  # The parameter must exist (reset to "pending") before the control plane
  # overwrites it, otherwise Terraform's create would collide with that write.
  depends_on = [aws_ssm_parameter.join_command]

  tags = {
    Name      = "${var.project_name}-control-plane"
    Project   = var.project_name
    ManagedBy = "terraform"
    Role      = "control-plane"
  }
}

resource "aws_instance" "worker" {
  count = var.worker_count

  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.worker_instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.nodes.id]
  key_name                    = aws_key_pair.this.key_name
  iam_instance_profile        = aws_iam_instance_profile.worker.name
  associate_public_ip_address = true

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.worker_root_volume_size
    encrypted             = true
    delete_on_termination = true
  }

  user_data = templatefile("${path.module}/templates/worker-init.sh.tftpl", {
    kubernetes_version = var.kubernetes_version
    region             = var.region
    project_name       = var.project_name
    node_name          = "worker-node-${count.index}"
  })

  # Not a hard requirement (the worker polls SSM and retries), but documents
  # the intended bring-up order.
  depends_on = [aws_instance.control_plane, aws_ssm_parameter.join_command]

  tags = {
    Name      = "${var.project_name}-worker-${count.index}"
    Project   = var.project_name
    ManagedBy = "terraform"
    Role      = "worker"
  }
}