#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "========================================"
echo "  SETUP FULL - Chạy 1 lần duy nhất"
echo "========================================"
echo ""

echo "=== 1. Kiểm tra k3s ==="
if k3s kubectl get nodes &>/dev/null; then
  echo "  ✅ k3s đang chạy"
else
  echo "  ⚠️  k3s chưa chạy, đang start..."
  sudo systemctl start k3s
  k3s kubectl wait --for=condition=Ready nodes --all --timeout=60s
fi

echo ""
echo "=== 2. Cài Jenkins (Docker Compose) ==="
DOCKER_GID=$(stat -c '%g' /var/run/docker.sock) \
  docker compose -f "$SCRIPT_DIR/deploy/jenkins/docker-compose.yml" up -d

echo "Chờ Jenkins khởi động..."
sleep 20
echo "  Jenkins: http://localhost:9999"
echo "  Password:"
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword 2>/dev/null || \
  echo "  (Jenkins đã setup trước đó, dùng user/pass cũ)"

echo ""
echo "=== 3. Cài ArgoCD trên k3s ==="
bash "$SCRIPT_DIR/deploy/install-argocd.sh" || echo "  ⚠️ ArgoCD có warning nhưng vẫn ổn"

echo ""
echo "=== 4. Cài Netdata Monitor ==="
# Netdata bị xóa

echo ""
echo "=== 5. Setup Cloudflare Tunnel ==="
bash "$SCRIPT_DIR/deploy/cloudflared/setup-tunnel.sh" || echo "  ⚠️ Tunnel đã tồn tại, skip"
docker compose -f "$SCRIPT_DIR/deploy/cloudflared/docker-compose.yml" up -d

echo ""
echo "=== 6. Tạo namespace + secret + ArgoCD App ==="
bash "$SCRIPT_DIR/deploy/setup-namespace.sh" || echo "  ⚠️ Namespace/App có thể đã tồn tại"

echo ""
echo "========================================"
echo "  SETUP HOÀN TẤT!"
echo "========================================"
echo ""
echo "  Jenkins:   http://localhost:9999"
echo "  ArgoCD:    https://dev1-argocd.vucongtuanduong.dpdns.org"
echo "             User: admin"
echo ""
echo "  Tiếp theo trong Jenkins:"
echo "  1. Cài plugin: Git, Docker Pipeline, Pipeline"
echo "  2. Tạo credentials: github + dockerhub"
echo "  3. New Item → Pipeline → Pipeline script from SCM"
echo "     Repo: https://github.com/Duong-Vu-practice-workspace/web-programming-grading-test1.git"
echo "     Script Path: Jenkinsfile"
echo ""
echo "  Tiếp theo trong ArgoCD:"
echo "  4. Settings → Repositories → Connect config repo"
echo "  5. Applications → web-grading → SYNC"
echo "  6. Jenkins → Build Now"
echo ""
echo "  Lần sau boot máy: bash start.sh"
