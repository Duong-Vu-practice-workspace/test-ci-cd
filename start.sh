#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== Start k3s ==="
sudo systemctl start k3s
kubectl wait --for=condition=Ready nodes --all --timeout=120s

echo "=== Start Cloudflare Tunnel ==="
docker compose -f "$SCRIPT_DIR/deploy/cloudflared/docker-compose.yml" up -d --no-build

echo ""
echo "=== All services ==="
echo " ArgoCD: https://dev1-argocd.vucongtuanduong.dpdns.org"
echo " API: https://dev1-api.vucongtuanduong.dpdns.org"
echo " Executor: https://dev1-executor.vucongtuanduong.dpdns.org"
