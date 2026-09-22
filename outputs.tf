output "control_plane_public_ip" {
  description = "Public IP of the control-plane node"
  value       = aws_instance.control_plane.public_ip
}

output "worker_public_ip" {
  description = "Public IP of the worker node"
  value       = aws_instance.worker.public_ip
}

output "ssh_control_plane" {
  description = "SSH command to reach the control-plane node"
  value       = "ssh -i ${local.ssh_private_key_path} ubuntu@${aws_instance.control_plane.public_ip}"
}

output "ssh_worker" {
  description = "SSH command to reach the worker node"
  value       = "ssh -i ${local.ssh_private_key_path} ubuntu@${aws_instance.worker.public_ip}"
}

output "fetch_kubeconfig_command" {
  description = "Commands to fetch the kubeconfig and reach it through an SSH tunnel to the control plane's own loopback (backgrounded as a shell job, kill with 'kill %1' in the same shell or 'pkill -f 6443:127.0.0.1:6443' from elsewhere). kubeadm's apiserver cert only covers the private IP and the service cluster IP, not 127.0.0.1, so TLS verification is disabled for this one cluster entry (fine for a personal lab; it's scoped to this kubeconfig file only, not your global kubectl trust settings)."
  value       = <<-EOT
    ssh -i ${local.ssh_private_key_path} -N -L 6443:127.0.0.1:6443 ubuntu@${aws_instance.control_plane.public_ip} &
    sleep 1  # give the tunnel a moment to establish before using it
    scp -i ${local.ssh_private_key_path} ubuntu@${aws_instance.control_plane.public_ip}:~/.kube/config ./kubeconfig
    export KUBECONFIG=$(pwd)/kubeconfig
    kubectl config unset clusters.kubernetes.certificate-authority-data
    kubectl config set-cluster kubernetes --server=https://127.0.0.1:6443 --insecure-skip-tls-verify=true
    kubectl get nodes
  EOT
}
