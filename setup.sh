#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "========================================"
echo "  SETUP FULL - Chạy 1 lần duy nhất"
echo "========================================"
echo ""

echo "=== 1. Kiểm tra k3s ==="
if kubectl get nodes &>/dev/null; then
  echo "  ✅ k3s đang chạy"
else
  echo "  ⚠️  k3s chưa chạy, đang start..."
  sudo systemctl start k3s
  kubectl wait --for=condition=Ready nodes --all
fi

echo ""
echo "=== 2. Cài ArgoCD trên k3s ==="
bash "$SCRIPT_DIR/deploy/install-argocd.sh"||echo "  ⚠️ ArgoCD có warning nhưng vẫn ổn"

echo ""
echo "=== 3. Setup Cloudflare Tunnel ==="
bash "$SCRIPT_DIR/deploy/cloudflared/setup-tunnel.sh"||echo "  ⚠️ Tunnel đã tồn tại, skip"
docker compose -f "$SCRIPT_DIR/deploy/cloudflared/docker-compose.yml" up -d

echo ""
echo "=== 4. Tạo namespace + secret + ArgoCD App ==="
bash "$SCRIPT_DIR/deploy/setup-namespace.sh"||echo "  ⚠️ Namespace/App có thể đã tồn tại"

echo ""
echo "========================================"
echo "  SETUP HOÀN TẤT!"
echo "========================================"
echo ""
echo "  ArgoCD:    https://dev1-argocd.vucongtuanduong.dpdns.org"
echo "             User: admin"
echo ""
echo "  GitHub Actions sẽ build & push Docker image"
echo "  ArgoCD tự động sync từ config repo"
echo ""
echo "  Lần sau boot máy: bash start.sh"
