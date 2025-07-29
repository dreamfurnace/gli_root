#!/usr/bin/env bash
set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 \"커밋 메시지\""
  exit 1
fi

commit_message="$1"

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

  if [ -d "$repo/.git" ]; then
    cd "$repo"

    if [[ -n $(git status --porcelain) || $(git log origin/main..HEAD) ]]; then
      echo "📦 변경사항 감지됨 → add → commit → push"
      git add -A
      git commit -m "$commit_message" || echo "📝 커밋할 변경사항 없음"
      git push origin main
    else
      echo "✅ 변경사항 없음 → skip"
    fi

    cd - > /dev/null
  else
    echo "⚠️ $repo는 Git 레포지토리가 아님"
  fi
done
