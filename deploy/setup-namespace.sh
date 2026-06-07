#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NAMESPACE="${1:-web-grading}"

echo "=== Tạo namespace ${NAMESPACE} ==="
kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -

echo "=== Tạo secret từ .env ==="
if [ -f "${SCRIPT_DIR}/../.env" ]; then
  set -o allexport
  source "${SCRIPT_DIR}/../.env"
  set +o allexport
fi

kubectl create secret generic web-grading-secret \
  --namespace "${NAMESPACE}" \
  --from-literal=GITHUB_TOKEN="${GITHUB_TOKEN:-}" \
  --from-literal=EXECUTOR_AUTH_TOKEN="${EXECUTOR_AUTH_TOKEN:-}" \
  --from-literal=API_AUTH_TOKEN="${API_AUTH_TOKEN:-}" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "=== Apply ArgoCD Application ==="
kubectl apply -f "$SCRIPT_DIR/argocd-application.yaml"
