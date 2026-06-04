#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== Installing Netdata ==="
k3s kubectl apply -f "$SCRIPT_DIR/netdata.yaml"

echo "Waiting for Netdata..."
k3s kubectl wait --namespace netdata \
  --for=condition=ready pod \
  --selector=app=netdata \
  --timeout=120s 2>/dev/null || true

echo ""
echo "=== Netdata installed ==="
echo "  URL: https://dev1-netdata.vucongtuanduong.dpdns.org"
echo "  Internal: http://netdata.netdata:19999"
