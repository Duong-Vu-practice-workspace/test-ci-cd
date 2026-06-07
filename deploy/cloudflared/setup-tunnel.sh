#!/usr/bin/env bash
set -euo pipefail

DOMAIN="${1:-vucongtuanduong.dpdns.org}"
TUNNEL_NAME="${2:-dev1-web-grading}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== Creating cloudflared tunnel: ${TUNNEL_NAME} ==="
if cloudflared tunnel info "${TUNNEL_NAME}" &>/dev/null; then
  echo "Tunnel ${TUNNEL_NAME} already exists, skipping creation"
else
  cloudflared tunnel create "${TUNNEL_NAME}"
fi

TUNNEL_ID=$(cloudflared tunnel info "${TUNNEL_NAME}" 2>&1 | grep -oP 'tunnel \K[a-f0-9-]+')
echo ""
echo "=== Tunnel ID: ${TUNNEL_ID} ==="

echo ""
echo "=== Cập nhật config.yml ==="
sed -i "s/tunnel: .*/tunnel: ${TUNNEL_ID}/" "${SCRIPT_DIR}/config.yml"
sed -i "s|credentials-file:.*|credentials-file: /etc/cloudflared/${TUNNEL_ID}.json|" "${SCRIPT_DIR}/config.yml"

echo "=== Copy config.yml vào ~/.cloudflared/ + fix permissions ==="
cp "${SCRIPT_DIR}/config.yml" ~/.cloudflared/config.yml
chmod 755 ~/.cloudflared
chmod 644 ~/.cloudflared/config.yml
chmod 644 ~/.cloudflared/${TUNNEL_ID}.json
echo "Done"

echo ""
echo "=== Route DNS từng subdomain ==="
cloudflared tunnel route dns "${TUNNEL_NAME}" "dev1-api.${DOMAIN}"||true
cloudflared tunnel route dns "${TUNNEL_NAME}" "dev1-executor.${DOMAIN}"||true
cloudflared tunnel route dns "${TUNNEL_NAME}" "dev1-argocd.${DOMAIN}"||true
cloudflared tunnel route dns "${TUNNEL_NAME}" "dev1-grafana.${DOMAIN}"||true

echo ""
echo "=== Nếu route DNS lỗi (domain không trên Cloudflare): ==="
echo "Thêm CNAME records tại DNS provider (dpdns.org):"
echo "  dev1-api      CNAME → ${TUNNEL_ID}.cfargotunnel.com"
echo "  dev1-executor CNAME → ${TUNNEL_ID}.cfargotunnel.com"

echo " dev1-argocd CNAME → ${TUNNEL_ID}.cfargotunnel.com"
echo " dev1-grafana CNAME → ${TUNNEL_ID}.cfargotunnel.com"

echo ""
echo "Xong thì chạy:"
echo "  docker compose -f ${SCRIPT_DIR}/docker-compose.yml up -d"
