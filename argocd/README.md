# argocd

ArgoCD on the cluster, in two phases:

1. **`bootstrap/`** — a one-time manual `helm install` of the `argo-helm/argo-cd` chart. See `bootstrap/README.md`.
2. **`self-managed/`** — once ArgoCD is running, it adopts and manages that same Helm release from this repo going forward, GitOps style.

## Cutting over from bootstrap to self-managed

After `bootstrap/` is up and healthy:

```bash
kubectl apply -f self-managed/application.yaml
kubectl -n argocd get application argocd -o wide   # wait for Synced / Healthy
```

`self-managed/application.yaml` points ArgoCD at the same `argo-helm/argo-cd` chart, pinned version, and values that `bootstrap/` installed with directly via Helm — so the resources it adopts should already match what it expects to manage. `syncPolicy.automated.{prune,selfHeal}` is on from this first sync; still worth watching it closely right after applying, since the bootstrap install's Helm-release bookkeeping (release name, ownership annotations) isn't the same as ArgoCD's own tracking:

```bash
kubectl -n argocd get application argocd -o yaml
kubectl -n argocd get pods   # confirm everything is still Running after the cutover
```

From this point on, ArgoCD's own configuration is changed by editing `self-managed/values.yaml` (or bumping the pinned chart `targetRevision` in `self-managed/application.yaml`) and pushing to git — not by `kubectl edit` or a manual `helm upgrade`.
