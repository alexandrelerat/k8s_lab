# terraform

A minimal, cheap Kubernetes cluster on AWS, provisioned with Terraform, for tinkering. No HA, no multi-AZ, no load balancer in front of the API server, no EKS: just a vanilla `kubeadm` control plane and two workers, with Flannel as the CNI, so pods can actually run.

All commands below assume you're inside this `terraform/` directory (`cd terraform`).

## What it creates

- A dedicated VPC (`10.0.0.0/16`), public subnet (`10.0.1.0/24`), internet gateway and route table
- Three EC2 instances (Ubuntu 22.04): one `t3.small` control plane and two `t3.medium` workers by default (`control_plane_instance_type`, `worker_instance_type`, `worker_count`). The workers get a 30GB root disk (`worker_root_volume_size`) since PersistentVolumes from `local-path-provisioner` live there
- A security group restricting SSH to your current public IP, with all traffic allowed between the nodes
- IAM roles letting the control plane publish the kubeadm join command to SSM Parameter Store, and the workers read it, so the join happens automatically with no manual copy-paste and no SSH key material shipped into instance metadata
- A fully bootstrapped cluster: containerd, kubelet/kubeadm/kubectl, `kubeadm init`, Flannel CNI, and the workers joined, all via `user_data` at boot

## Prerequisites

```bash
brew install awscli   # if not already installed
aws configure          # or: aws sso login --profile <name>
```

You'll also need an existing SSH keypair (this project registers your existing public key, it doesn't generate one for you):

```bash
ls ~/.ssh/id_ed25519.pub   # or generate one: ssh-keygen -t ed25519
```

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars: set ssh_public_key_path, and aws_profile if you use a named profile

terraform init
terraform plan
terraform apply
```

`terraform output` gives you ready-to-run `ssh` and kubeconfig-fetch commands.

Bootstrap takes a couple of minutes after the instances come up (containerd + kubeadm install + init + join). If `kubectl get nodes` doesn't show the workers yet, SSH in and check:

```bash
cloud-init status --wait
tail -f /var/log/k8s-bootstrap.log
```

## Verifying the cluster

```bash
ssh -i <key> ubuntu@<control-plane-ip>
kubectl get nodes           # all three nodes should be Ready
kubectl get pods -A         # kube-system pods (etcd, apiserver, coredns, flannel, ...) should all be Running
```

Or from your laptop, using the `fetch_kubeconfig_command` output:

```bash
scp -i <key> ubuntu@<control-plane-ip>:~/.kube/config ./kubeconfig
sed -i '' 's#10.0.1.10#<control-plane-ip>#' ./kubeconfig   # macOS/BSD sed; drop the empty '' on GNU sed
export KUBECONFIG=$(pwd)/kubeconfig
kubectl get nodes
```

Smoke test that pod networking actually works end to end:

```bash
kubectl run test --image=busybox --command -- sleep 3600
kubectl get pod test -o wide   # should schedule on a worker, get a 10.244.0.0/16 IP
```

## Cost

Roughly, in `eu-west-3`:
- 1x `t3.small` (control plane): ~$0.024/hr
- 2x `t3.medium` (workers): ~$0.048/hr each
- So ~$0.12/hr, ~$87/month if left running continuously
- 1x 20GB + 2x 30GB `gp3` EBS: ~$8/month

**`terraform destroy` is what stops the billing**, not stopping the instances. Since the whole cluster rebuilds automatically from `user_data` on the next `apply`, destroying between tinkering sessions is the intended way to keep this cheap.

## Notes

- If your public IP changes, SSH will stop working until you run `terraform apply` again (it re-detects your current IP each time), or set `allowed_ssh_cidr` explicitly in `terraform.tfvars`.
- No StorageClass/PV setup is included at the Terraform level. `../observability/` installs Rancher's [`local-path-provisioner`](https://github.com/rancher/local-path-provisioner) through ArgoCD as the default StorageClass, which avoids the AWS EBS CSI driver's IAM/DaemonSet complexity.
- Ansible is intentionally not used here. The entire bootstrap runs once via `user_data` at instance boot; there's no ongoing app-layer configuration to manage that would justify it.
