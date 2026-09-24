# argocd/bootstrap

One-time manual install of ArgoCD via Helm, using the exact same chart, pinned version, and values that `../self-managed/` hands control to afterward, so the cutover to self-management doesn't change anything.

This is only ever run once, to get an ArgoCD running well enough to adopt its own management via `../self-managed/`.

## Steps

```bash
export KUBECONFIG=$(pwd)/../../terraform/kubeconfig   # or use terraform output's fetch command

helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

helm install argocd argo/argo-cd \
  -n argocd --create-namespace \
  --version 10.9.2 \
  -f ../self-managed/values.yaml

kubectl -n argocd get pods -w   # wait until all pods are Running
```

Get the initial admin password:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
```

Reach the UI or CLI:

```bash
kubectl -n argocd port-forward svc/argocd-server 8080:443
# then open https://localhost:8080, user "admin"
```

Once you've confirmed ArgoCD is up, move on to `../self-managed/` to hand its own management over to itself.
