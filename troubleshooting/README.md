# troubleshooting

Four standalone Kubernetes manifests, each with one intentional bug. Meant to be applied to the cluster from `../terraform/` and debugged from scratch, not read before you try.

## Usage

```bash
export KUBECONFIG=$(pwd)/../terraform/kubeconfig   # or use terraform output's fetch command
kubectl apply -f 01-frontend.yaml
```

Observe the failure (`kubectl get pods`, `kubectl describe`, `kubectl get events`, `kubectl logs`), form a hypothesis, and fix it either by editing the manifest and re-applying, or with `kubectl edit`/`kubectl patch` directly.

## Exercises

- `01-frontend.yaml` — a Deployment and Service that should route traffic to it, but don't.
- `02-payments-worker.yaml` — a Deployment that keeps crash-looping.
- `03-analytics-store.yaml` — a Pod stuck pending, with storage involved.
- `04-api-gateway.yaml` — a Deployment and NodePort Service that isn't reachable.

Clean up with `kubectl delete -f <file>` between attempts.
