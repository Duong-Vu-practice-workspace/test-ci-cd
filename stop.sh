#!/usr/bin/env bash
set -euo pipefail

echo "=== Dừng Jenkins & Cloudflare Tunnel ==="
docker stop jenkins 2>/dev/null && echo "✔ Jenkins stopped" || echo "  - không chạy"
docker stop cloudflared-dev1 2>/dev/null && echo "✔ Cloudflared stopped" || echo "  - không chạy"

echo ""
echo "=== Dừng k3s ==="
sudo systemctl stop k3s 2>/dev/null && echo "✔ k3s stopped" || echo "  - không chạy"

echo ""
echo "=== Xong ==="
