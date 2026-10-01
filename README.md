# k8s_lab

A personal Kubernetes learning lab on AWS. Each top-level folder is a self-contained lab:

- **[`terraform/`](terraform/README.md)** — provisions the cluster itself: a minimal `kubeadm` control plane and two workers on EC2, with Flannel as the CNI.
- **[`troubleshooting/`](troubleshooting/README.md)** — standalone "spot the bug" manifests to practice debugging against the running cluster.
- **[`argocd/`](argocd/README.md)** — stands up ArgoCD on the cluster, first via a one-time manual install, then hands its own management over to itself via Helm/GitOps.
- **[`observability/`](observability/README.md)**: an OpenTelemetry pipeline deployed by ArgoCD, with OTel-instrumented demo apps behind a Traefik ingress, an OTel Collector, Prometheus and Tempo as backends, Grafana on top.

Start with `terraform/` to get a cluster up, then use `troubleshooting/` or `argocd/` against it. `observability/` needs `argocd/` installed first.
