resource "aws_key_pair" "this" {
  key_name   = "${var.project_name}-key"
  public_key = trimspace(file(pathexpand(var.ssh_public_key_path)))

  tags = {
    Project = var.project_name
  }
}

# Required between control-plane and worker for kubeadm/kubelet/etcd/flannel:
#   6443/tcp        kube-apiserver
#   2379-2380/tcp   etcd (control-plane only, but harmless to allow both ways)
#   10250/tcp       kubelet API (both nodes)
#   10259/tcp       kube-scheduler (control-plane)
#   10257/tcp       kube-controller-manager (control-plane)
#   8472/udp        flannel VXLAN overlay
#   30000-32767/tcp NodePort range (worker)
# Covered by a single self-referencing rule below instead of enumerating each one,
# since this security group only ever has these two lab nodes as members.
resource "aws_security_group" "nodes" {
  name        = "${var.project_name}-nodes"
  description = "K8s lab node security group: SSH from operator IP, all traffic between cluster nodes"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "SSH from operator IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [local.allowed_ssh_cidr]
  }

  ingress {
    description = "All traffic between cluster nodes"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-nodes"
    Project = var.project_name
  }
}
