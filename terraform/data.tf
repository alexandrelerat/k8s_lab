data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_caller_identity" "current" {}

data "http" "my_ip" {
  count = var.allowed_ssh_cidr == null ? 1 : 0
  url   = "https://checkip.amazonaws.com"
}

locals {
  allowed_ssh_cidr = coalesce(var.allowed_ssh_cidr, "${chomp(data.http.my_ip[0].response_body)}/32")
  cp_private_ip    = "10.0.1.10"

  # Assumes the conventional pairing of <name>.pub / <name>, which is how
  # ssh-keygen names keys by default.
  ssh_private_key_path = trimsuffix(var.ssh_public_key_path, ".pub")
}
