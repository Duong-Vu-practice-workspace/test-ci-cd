#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== Start k3s ==="
sudo systemctl start k3s
k3s kubectl wait --for=condition=Ready nodes --all --timeout=60s

echo "=== Start Jenkins ==="
DOCKER_GID=$(stat -c '%g' /var/run/docker.sock) \
  docker compose -f "$SCRIPT_DIR/deploy/jenkins/docker-compose.yml" up -d --no-build

echo "=== Start Cloudflare Tunnel ==="
docker compose -f "$SCRIPT_DIR/deploy/cloudflared/docker-compose.yml" up -d --no-build

echo ""
echo "=== All services ==="
echo "  Jenkins:   http://localhost:9999"
echo "  ArgoCD:    https://dev1-argocd.vucongtuanduong.dpdns.org"
echo "  API:       https://dev1-api.vucongtuanduong.dpdns.org"
echo "  Executor:  https://dev1-executor.vucongtuanduong.dpdns.org"
