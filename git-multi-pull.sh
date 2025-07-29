#!/usr/bin/env bash
set -euo pipefail

GITHUB_ORG="dreamfurnace"
REPOS=(
  .
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
  echo
  echo "====== $repo ======"

  if [ -d "$repo" ] && [ ! -d "$repo/.git" ]; then
    echo "⚠️ $repo에 .git 없음 → 삭제 후 재클론"
    rm -rf "$repo"
  fi

  if [ ! -d "$repo" ]; then
    echo "📥 Cloning $repo…"
    git clone "git@github.com:$GITHUB_ORG/$repo.git" "$repo"
  fi

  echo "⬇ Pulling latest from $repo..."
  git -C "$repo" pull origin main
done

echo
echo "✅ 모든 레포 최신화 완료!"
