#!/bin/bash
set -e

EXPECTED_CONTEXT="rancher-desktop"

echo "🔍 Checking current kubectl context..."
CURRENT_CONTEXT=$(kubectl config current-context)

if [[ "$CURRENT_CONTEXT" != "$EXPECTED_CONTEXT" ]]; then
  echo "You are not connected to the expected Kubernetes context: '$EXPECTED_CONTEXT'"
  echo "   Current context is: '$CURRENT_CONTEXT'"
  echo "Run 'kubectl config use-context $EXPECTED_CONTEXT' to switch."
  exit 1
fi

echo "Connected to expected context: '$CURRENT_CONTEXT'"


# Add argocd.local to /etc/hosts if it's not already present
if ! grep -q "argocd.local" /etc/hosts; then
  echo "🔧 Adding argocd.local to /etc/hosts (requires sudo)..."
  echo "127.0.0.1 argocd.local" | sudo tee -a /etc/hosts > /dev/null
else
  echo "✅ argocd.local already present in /etc/hosts"
fi

echo "🌐 Applying ArgoCD Ingress for Traefik (https://argocd.local)..."
kubectl apply -f argocd-cmd-params-cm.yaml

# Generate self-signed TLS cert if not exists
if [[ ! -f "argocd.crt" || ! -f "argocd.key" ]]; then
  echo "🔐 Generating self-signed TLS cert for argocd.local..."
  openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout argocd.key -out argocd.crt \
    -subj "/CN=argocd.local/O=argocd.local"
else
  echo "🔐 Reusing existing argocd.crt and argocd.key"
fi

echo "🔐 Creating/updating TLS secret in argocd namespace..."
kubectl delete secret argocd-tls -n argocd --ignore-not-found
kubectl create secret tls argocd-tls \
  --cert=argocd.crt \
  --key=argocd.key \
  -n argocd

# Restart argocd-server to pick up --insecure config
echo "🔄 Restarting argocd-server..."
kubectl -n argocd rollout restart deployment argocd-server

# Wait for rollout to complete
kubectl -n argocd rollout status deployment argocd-server

kubectl apply -f argocd-ingress.yaml

echo "🧩 Registering App of Apps..."
kubectl apply -f app-of-apps.yaml

echo "🚀 Setup complete. Access ArgoCD at: https://argocd.local"


