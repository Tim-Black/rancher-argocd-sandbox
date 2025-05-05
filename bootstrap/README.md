# ArgoCD Bootstrap (Rancher Desktop Edition)

This folder bootstraps a Kubernetes cluster with [Argo CD](https://argo-cd.readthedocs.io) using the **App of Apps pattern**. It automates deployment of applications like Grafana and Guestbook in a GitOps-compliant way.

> ⚠️ Target environment: Local Kubernetes via Rancher Desktop with Traefik as the default Ingress controller.

---

## 🔧 What This Does

- Installs ArgoCD into the cluster.
- Exposes the ArgoCD UI at **https://argocd.local**.
- Bootstraps child ArgoCD applications via a central "App of Apps".
- Deploys each application (e.g., Grafana, Guestbook) with separate configurations for `dev` and `prod`.

---

## 📁 Folder Structure

```
bootstrap/
├── app-of-apps.yaml          # Registers all child applications with ArgoCD
├── argocd-ingress.yaml       # Traefik ingress to access ArgoCD locally
├── bootstrap.sh              # Automates install + config + login
├── apps/
│   ├── grafana-dev.yaml
│   ├── grafana-prod.yaml
│   ├── guestbook-dev.yaml
│   └── guestbook-prod.yaml
└── README.md                 # You're reading it
```

---

## 🚀 Quick Start

> ⚠️ Assumes: Rancher Desktop is running with Kubernetes, and `kubectl` & `argocd` CLI are installed.

1. **Clone the repository**
   ```bash
   git clone git@github.com:Romiko/rancher-argocd-sandbox.git
   cd rancher-argocd-sandbox/bootstrap
   ```

2. **Run the bootstrap script**
   ```bash
   ./bootstrap.sh
   ```

3. **Access ArgoCD UI**
   Open [https://argocd.local](https://argocd.local) in your browser.

4. **Login to ArgoCD**
   - **Username**: `admin`
   - **Password**: Get the server pod name:
     ```bash
     kubectl -n argocd get pods -l app.kubernetes.io/name=argocd-server -o name | cut -d'/' -f2
     ```

---

## 📦 Applications

| Name       | Source                     | Chart Type | Namespace       |
|------------|----------------------------|------------|-----------------|
| Grafana    | grafana.github.io Helm repo | External   | `grafana-dev`   |
| Guestbook  | Local Helm chart            | Internal   | `guestbook-dev` |

Each app has its own `values-dev.yaml` and `values-prod.yaml` in the root of its folder.

---

## 📌 Notes

- All apps are **automatically synced and self-healing** (`syncPolicy: automated`).
- This repo uses the **App of Apps** pattern — one parent Application manages all child apps.
- The script also updates your `/etc/hosts` file so `https://argocd.local` works.
- **Only the parent app** needs to be applied manually — everything else is bootstrapped from Git.

---

## 🧼 Cleanup

To remove everything:
```bash
kubectl delete ns argocd grafana-dev guestbook-dev grafana-prod guestbook-prod
```

---

## 🧠 Want to go further?

- Add `AppProject` definitions to control app access per team.
- Add `finalizers` to clean up child apps automatically.
- Set `targetRevision` to a Git tag or commit for prod apps (not just `HEAD`).

---
