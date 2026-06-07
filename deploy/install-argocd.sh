#!/usr/bin/env bash
set -euo pipefail

echo "=== Installing ArgoCD on k3s ==="

kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml||true

echo "Waiting for ArgoCD pods..."
kubectl wait --namespace argocd \
 --for=condition=ready pod \
 --selector=app.kubernetes.io/component=server \
 --timeout=120s 2>/dev/null||true

# Configure ArgoCD to allow HTTP behind reverse proxy (Traefik)
kubectl patch deployment argocd-server -n argocd --type='json' -p="[
 {
 \"op\": \"replace\",
 \"path\": \"/spec/template/spec/containers/0/args\",
 \"value\": [\"/usr/local/bin/argocd-server\", \"--insecure\"]
 }
]" 2>/dev/null||true

kubectl rollout status deployment argocd-server -n argocd 2>/dev/null||true

# Apply Ingress for ArgoCD
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
kubectl apply -f "$SCRIPT_DIR/argocd-ingress.yaml"

# Expose argocd-server service as ClusterIP (Traefik handles external access)
kubectl patch svc -n argocd argocd-server --patch '{"spec": {"type":"ClusterIP"}}'

ARGO_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

echo ""
echo "=== ArgoCD installed ==="
echo " URL: https://dev1-argocd.vucongtuanduong.dpdns.org"
echo " User: admin"
echo " Pass: ${ARGO_PASSWORD}"
echo ""
echo "=== Next steps: ==="
echo " 1. Login to ArgoCD web UI"
echo " 2. Settings > Repositories > Connect repo > Via HTTPS"
echo " - URL: https://github.com/Duong-Vu-practice-workspace/web-programming-grading-config-test1.git"
echo " - Username/Password: your github token"
echo " 3. kubectl apply -f deploy/argocd-application.yaml"
