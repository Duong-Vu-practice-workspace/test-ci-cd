#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NAMESPACE="observability"

export PATH="$HOME/.local/bin:$PATH"

echo "=== Creating namespace ==="
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

echo "=== Installing kube-prometheus-stack (Prometheus + Grafana) ==="
helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace "$NAMESPACE" \
  --values "$SCRIPT_DIR/kube-prometheus-stack/values.yaml" \
  --wait --timeout 10m

echo "=== Installing Loki + Promtail ==="
helm upgrade --install loki grafana/loki \
  --namespace "$NAMESPACE" \
  --values "$SCRIPT_DIR/loki/values.yaml" \
  --wait --timeout 10m

echo "=== Installing Tempo ==="
helm upgrade --install tempo grafana/tempo \
  --namespace "$NAMESPACE" \
  --values "$SCRIPT_DIR/tempo/values.yaml" \
  --wait --timeout 10m

echo "=== Installing OpenTelemetry Collector ==="
helm upgrade --install otel-collector open-telemetry/opentelemetry-collector \
  --namespace "$NAMESPACE" \
  --values "$SCRIPT_DIR/otel-collector/values.yaml" \
  --wait --timeout 10m

echo ""
echo "=== All components installed ==="
echo ""
echo "Grafana:     http://localhost:30300 (admin / admin)"
echo "Datasources configured: Prometheus, Loki, Tempo"
echo ""
echo "OTel Collector endpoints:"
echo "  gRPC: otel-collector.observability.svc:4317"
echo "  HTTP: otel-collector.observability.svc:4318"
echo ""
echo "Tempo:       tempo.observability.svc:4317 (OTLP gRPC)"
echo "Loki:        loki.observability.svc:3100"
echo "Prometheus:  kube-prometheus-stack-prometheus.observability.svc:9090"
