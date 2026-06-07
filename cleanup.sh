#!/usr/bin/env bash
set -euo pipefail

echo "============================================"
echo "  CLEANUP - Giải phóng tài nguyên"
echo "  (Giữ lại Jenkins volume + cloudflared)"
echo "============================================"

read -p "Chắc chắn muốn xóa? (y/N): " confirm
[[ "$confirm" != "y" ]] && echo "Huỷ" && exit 0

echo ""
echo "=== 1. Xóa containers (giữ volume) ==="
docker rm -f jenkins 2>/dev/null && echo "  ✗ Jenkins" || echo "  - không có"
docker rm -f cloudflared-dev1 2>/dev/null && echo "  ✗ cloudflared" || echo "  - không có"

echo ""
echo "=== 2. Xóa Docker images cũ (giữ :latest + my-jenkins) ==="
docker rmi -f \
  vucongtuanduong/web-grading-api:v1.1 \
  vucongtuanduong/web-grading-api:v1.2 \
  vucongtuanduong/web-grading-api:v1.3 \
  vucongtuanduong/web-grading-api:v1.4 \
  vucongtuanduong/web-grading-api:v1.5 \
  vucongtuanduong/web-grading-executor:v1.1 \
  vucongtuanduong/web-grading-executor:v1.2 \
  vucongtuanduong/web-grading-executor:v1.3 \
  vucongtuanduong/web-grading-executor:v1.4 \
  vucongtuanduong/web-grading-executor:v1.5 \
  2>/dev/null && echo "  ✗ Images cũ" || echo "  - không có"

docker system prune -f && echo "  ✗ Build cache"

echo ""
echo "=== 3. Start k3s nếu chưa chạy (để clean resources) ==="
if ! systemctl is-active --quiet k3s; then
  sudo systemctl start k3s
  k3s kubectl wait --for=condition=Ready nodes --all --timeout=60s
  echo "  ✗ k3s started"
else
  echo "  - đang chạy"
fi

echo ""
echo "=== 4. Xóa Observability stack ==="
helm uninstall kube-prometheus-stack -n observability 2>/dev/null && echo " ✗ kube-prometheus-stack"||echo " - không có"
helm uninstall loki -n observability 2>/dev/null && echo " ✗ loki"||echo " - không có"
helm uninstall tempo -n observability 2>/dev/null && echo " ✗ tempo"||echo " - không có"
helm uninstall otel-collector -n observability 2>/dev/null && echo " ✗ otel-collector"||echo " - không có"
kubectl delete namespace observability --ignore-not-found 2>/dev/null && echo " ✗ namespace observability"||echo " - không có"

echo ""
echo "=== 5. Xóa ArgoCD + ứng dụng trên k3s ==="
k3s kubectl delete namespace argocd --ignore-not-found 2>/dev/null && echo "  ✗ ArgoCD" || echo "  - không có"
k3s kubectl delete namespace web-grading --ignore-not-found 2>/dev/null && echo "  ✗ web-grading" || echo "  - không có"

echo ""
echo "=== 5. Xóa tất cả images trong containerd ==="
sudo k3s ctr images rm $(sudo k3s ctr images ls -q) 2>/dev/null && echo "  ✗ containerd images deleted" || echo "  - không có"

echo ""
echo "=== 6. Dừng k3s ==="
sudo systemctl stop k3s 2>/dev/null && echo "  ✗ k3s stopped" || echo "  - không chạy"

echo ""
echo "============================================"
echo "  XONG! Giữ lại được:"
echo "  - Jenkins data (volume jenkins_home)"
echo "  - Cloudflare tunnel"
echo "  - Docker images :latest"
echo ""
echo "  Chạy lại: bash start.sh"
echo "============================================"
df -h / | tail -1
