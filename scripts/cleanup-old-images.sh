#!/usr/bin/env bash
set -euo pipefail

TMP_DIR=$(mktemp -d)
git clone --depth 1 https://github.com/Duong-Vu-practice-workspace/web-programming-grading-config-test1.git "$TMP_DIR" 2>/dev/null

CURRENT_TAG=$(grep '^  tag:' "$TMP_DIR/values-stg.yaml" | awk '{print $2}' | tr -d '"')
rm -rf "$TMP_DIR"

echo "Tag hiện tại: $CURRENT_TAG"
echo ""

sudo k3s crictl images --output json 2>/dev/null | python3 -c "
import json, sys, subprocess

current_tag = '$CURRENT_TAG'
data = json.load(sys.stdin)

for img in data.get('images', []):
    for repo_tag in img.get('repoTags', []):
        if 'web-grading' not in repo_tag:
            continue
        tag = repo_tag.rsplit(':', 1)[1] if ':' in repo_tag else 'latest'
        if tag == current_tag:
            continue
        print(f'Xoá: {repo_tag}')
        subprocess.run(['sudo', 'k3s', 'crictl', 'rmi', img['id']])
"
echo "Done"
