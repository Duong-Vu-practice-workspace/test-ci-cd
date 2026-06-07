#!/usr/bin/env bash
set -euo pipefail

echo "=== Clean up Observability stack ==="

helm uninstall kube-prometheus-stack -n observability 2>/dev/null || true
helm uninstall loki -n observability 2>/dev/null || true
helm uninstall tempo -n observability 2>/dev/null || true
helm uninstall otel-collector -n observability 2>/dev/null || true

kubectl delete namespace observability --wait 2>/dev/null || true

echo "=== Cleaning ArgoCD ==="
helm uninstall argo-cd -n argocd 2>/dev/null || true
kubectl delete namespace argocd --wait 2>/dev/null || true

echo "=== Cleaning web-grading ==="
kubectl delete namespace web-grading --wait 2>/dev/null || true

echo "=== Cleanup done ==="
