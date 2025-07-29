#!/bin/bash
set -e

GITHUB_ORG="dreamfurnace"

REPOS=(
  gli_user-frontend
  gli_admin-frontend
  gli_api-server
  gli_ai-core
  gli_database
  gli_docs
  gli_infra
  gli_rabbitmq
  gli_ws-server
)

for repo in "${REPOS[@]}"; do
  if [ ! -d "$repo" ]; then
    echo "📥 클론: $repo"
    git clone git@github.com:$GITHUB_ORG/$repo.git
  else
    echo "✅ 이미 존재: $repo"
  fi
done

echo "🔄 모든 하위 레포 클론 완료!"
