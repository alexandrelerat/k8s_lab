variable "region" {
  description = "AWS region to deploy the lab in"
  type        = string
  default     = "eu-west-3"
}

variable "aws_profile" {
  description = "Optional named AWS CLI profile. Leave null to use the default credential chain."
  type        = string
  default     = null
}

variable "control_plane_instance_type" {
  description = "EC2 instance type for the control-plane node"
  type        = string
  default     = "t3.small"
}

variable "worker_instance_type" {
  description = "EC2 instance type for the worker nodes"
  type        = string
  default     = "t3.medium"
}

variable "worker_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 2
}

variable "worker_root_volume_size" {
  description = "Root EBS volume size (GiB) of each worker. PersistentVolumes from local-path-provisioner live on this disk."
  type        = number
  default     = 30
}

variable "ssh_public_key_path" {
  description = "Path to an existing local SSH public key, e.g. ~/.ssh/id_ed25519.pub"
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "CIDR allowed to SSH into the nodes. Leave null to auto-detect your current public IP at apply time."
  type        = string
  default     = null
}

variable "kubernetes_version" {
  description = "Kubernetes minor version to install (matches the pkgs.k8s.io stable repo path), e.g. 1.30"
  type        = string
  default     = "1.30"
}

variable "project_name" {
  description = "Name prefix used for tagging and the SSM parameter path"
  type        = string
  default     = "k8s-lab"
}
