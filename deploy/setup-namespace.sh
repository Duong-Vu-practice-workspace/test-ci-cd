#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=== Creating web-grading namespace ==="
k3s kubectl create namespace web-grading --dry-run=client -o yaml | k3s kubectl apply -f -

ENV_FILE="$PROJECT_DIR/backend/web_programming_grading/.env"
echo "=== Creating secrets from $ENV_FILE ==="
if [ -f "$ENV_FILE" ]; then
  DB_URL=$(grep -m1 '^DB_URL=' "$ENV_FILE" | cut -d= -f2-)
  DB_USERNAME=$(grep -m1 '^DB_USERNAME=' "$ENV_FILE" | cut -d= -f2-)
  DB_PASSWORD=$(grep -m1 '^DB_PASSWORD=' "$ENV_FILE" | cut -d= -f2-)

  k3s kubectl create secret generic db-secret \
    --namespace web-grading \
    --from-literal=DB_URL="${DB_URL}" \
    --from-literal=DB_USERNAME="${DB_USERNAME}" \
    --from-literal=DB_PASSWORD="${DB_PASSWORD}" \
    --dry-run=client -o yaml | k3s kubectl apply -f -
else
  echo "WARNING: .env file not found at $ENV_FILE, tạo bằng tay:"
  echo "  k3s kubectl create secret generic db-secret -n web-grading"
  echo "    --from-literal=DB_URL=... --from-literal=DB_USERNAME=... --from-literal=DB_PASSWORD=..."
fi

echo ""
echo "=== Apply ArgoCD Application ==="
k3s kubectl apply -f "$SCRIPT_DIR/argocd-application.yaml"
