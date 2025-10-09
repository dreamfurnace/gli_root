#!/usr/bin/env bash
set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 \"커밋 메시지\""
  exit 1
fi

commit_message="$1"

repos=(
  .
  gli_redis
  gli_user-frontend
  gli_admin-frontend
  gli_api-server
  gli_database
  gli_rabbitmq
  gli_websocket
)

for repo in "${repos[@]}"; do
  echo
  echo "====== $repo ======"

  if [ -d "$repo/.git" ]; then
    cd "$repo"

    # main 브랜치로 전환
    git checkout main

    # 변경된 파일 있는지 확인 (변경하고 커밋을 해도 푸쉬를 하지 않았으면 감지함)
    if [[ -n $(git status --porcelain) || $(git log origin/main..HEAD) ]]; then

      echo "📦 변경사항 있음 → add → commit → push"

      # .DS_Store 파일 제거 및 .gitignore에 추가
      find . -name ".DS_Store" -delete
      if ! grep -q "^\.DS_Store$" .gitignore 2>/dev/null; then
        echo ".DS_Store" >> .gitignore
      fi
      # 이미 추적되고 있는 .DS_Store 파일들을 Git에서 제거
      git rm --cached .DS_Store 2>/dev/null || true
      git add -A

      # 아래는 커밋할게 없을 경우 종료됨
      # git commit -m "$commit_message"

      # 아래는 커밋할게 없어도 푸쉬함
      git commit -m "$commit_message" || echo "📝 커밋할 변경사항 없음 (skip)"

      git push origin main
    else
      echo "✅ 변경사항 없음 → skip"
    fi

    cd - > /dev/null
  else
    echo "⚠️ 폴더 '$repo'는 Git 레포지토리가 아닙니다."
  fi
done
