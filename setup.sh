#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "========================================"
echo "  SETUP FULL - 1 lần duy nhất từ đầu"
echo "========================================"

echo ""
echo "=== 1. Kiểm tra / khởi động k3s ==="
if kubectl get nodes &>/dev/null; then
  echo "  ✅ k3s đang chạy"
else
  echo "  🚀 Đang start k3s..."
  sudo systemctl start k3s
  kubectl wait --for=condition=Ready nodes --all --timeout=60s
fi

echo ""
echo "=== 2. Cài ArgoCD ==="
bash "$SCRIPT_DIR/deploy/install-argocd.sh"

echo ""
echo "=== 3. Setup Cloudflare Tunnel ==="
bash "$SCRIPT_DIR/deploy/cloudflared/setup-tunnel.sh" || echo "  ℹ️  Tunnel có thể đã tồn tại, skip"
docker compose -f "$SCRIPT_DIR/deploy/cloudflared/docker-compose.yml" up -d

echo ""
echo "=== 4. Tạo namespace + secret + ArgoCD App ==="
bash "$SCRIPT_DIR/deploy/setup-namespace.sh"

echo ""
echo "=== 5. Add Helm repos cho Observability ==="
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 2>/dev/null || true
helm repo add grafana https://grafana.github.io/helm-charts 2>/dev/null || true
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts 2>/dev/null || true
helm repo update

echo ""
echo "=== 6. Deploy Observability Stack ==="
kubectl create namespace observability --dry-run=client -o yaml | kubectl apply -f -

helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace observability \
  --values "$SCRIPT_DIR/deploy/observability/kube-prometheus-stack/values.yaml" \
  --timeout 5m

helm upgrade --install loki grafana/loki \
  --namespace observability \
  --values "$SCRIPT_DIR/deploy/observability/loki/values.yaml" \
  --timeout 5m

helm upgrade --install tempo grafana/tempo \
  --namespace observability \
  --values "$SCRIPT_DIR/deploy/observability/tempo/values.yaml" \
  --timeout 5m

helm upgrade --install otel-collector open-telemetry/opentelemetry-collector \
  --namespace observability \
  --values "$SCRIPT_DIR/deploy/observability/otel-collector/values.yaml" \
  --timeout 5m

echo ""
echo "========================================"
echo "  SETUP HOÀN TẤT!"
echo "========================================"
echo ""
echo "  ArgoCD:    https://dev1-argocd.vucongtuanduong.dpdns.org (admin)"
echo "  Grafana:   NodePort 30300 (admin / admin)"
echo ""
echo "  Observability:"
echo "    OTel Collector: otel-collector.observability.svc:4317 (gRPC)"
echo "    Tempo:          tempo.observability.svc:4317 (OTLP)"
echo "    Loki:           loki.observability.svc:3100"
echo "    Prometheus:     kube-prometheus-stack-prometheus.observability.svc:9090"
echo ""
echo "  Sau này boot lại: bash start.sh"
