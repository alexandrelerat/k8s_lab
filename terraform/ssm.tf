# Join command handoff between the control plane and the workers. Terraform
# owns the parameter so that `destroy` deletes it and every `apply` starts
# from the "pending" placeholder: without this, workers of a new cluster would
# read the previous cluster's join command and fail with an invalid token.
# The control plane overwrites the value at boot, hence ignore_changes.
resource "aws_ssm_parameter" "join_command" {
  name  = "/${var.project_name}/join-command"
  type  = "SecureString"
  value = "pending"

  lifecycle {
    ignore_changes = [value]
  }

  tags = {
    Project   = var.project_name
    ManagedBy = "terraform"
  }
}
