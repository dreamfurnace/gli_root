#!/bin/bash

# GLI Project - Pull stg branch across all repositories
# 모든 리포지토리의 stg 브랜치를 최신화

set -e

REPOS=(
  .
  gli_admin-frontend
  gli_api-server
  gli_database
  gli_rabbitmq
  gli_redis
  gli_user-frontend
  gli_websocket
)

SUCCESS_REPOS=()
FAILED_REPOS=()

echo "================================================"
echo "GLI MultiGit: Pull stg branch"
echo "================================================"
echo ""
echo "모든 리포지토리의 stg 브랜치를 최신 상태로 업데이트합니다."
echo ""

for repo in "${REPOS[@]}"; do
  if [ "$repo" = "." ]; then
    REPO_NAME="gli_root"
  else
    REPO_NAME="$repo"
  fi

  echo "📦 $REPO_NAME"
  echo "----------------------------------------"

  cd "$repo"

  # Check if stg branch exists
  if ! git rev-parse --verify stg > /dev/null 2>&1; then
    echo "  ⚠️  stg 브랜치가 존재하지 않습니다. 건너뜁니다."
    FAILED_REPOS+=("$REPO_NAME (no stg branch)")
    cd - > /dev/null
    echo ""
    continue
  fi

  # Switch to stg branch
  echo "  1️⃣ stg 브랜치로 전환..."
  if git checkout stg > /dev/null 2>&1; then
    echo "  ✅ stg 브랜치로 전환 완료"
  else
    echo "  ❌ stg 브랜치로 전환 실패"
    FAILED_REPOS+=("$REPO_NAME")
    cd - > /dev/null
    echo ""
    continue
  fi

  # Pull latest changes
  echo "  2️⃣ 원격 저장소에서 최신 변경사항 가져오기..."
  if git pull origin stg; then
    echo "  ✅ Pull 성공"
    SUCCESS_REPOS+=("$REPO_NAME")
  else
    echo "  ❌ Pull 실패 (충돌이 발생했을 수 있습니다)"
    echo "  해결 방법:"
    echo "    cd $repo"
    echo "    git status"
    echo "    # 충돌 해결 후"
    echo "    git add ."
    echo "    git commit"
    FAILED_REPOS+=("$REPO_NAME")
  fi

  cd - > /dev/null
  echo ""
done

echo "================================================"
echo "Summary"
echo "================================================"
echo "✅ 성공한 리포지토리 (${#SUCCESS_REPOS[@]}):"
for repo in "${SUCCESS_REPOS[@]}"; do
  echo "  - $repo"
done

if [ ${#FAILED_REPOS[@]} -gt 0 ]; then
  echo ""
  echo "❌ 실패한 리포지토리 (${#FAILED_REPOS[@]}):"
  for repo in "${FAILED_REPOS[@]}"; do
    echo "  - $repo"
  done
  echo ""
  echo "⚠️  실패한 리포지토리를 수동으로 확인하세요."
  exit 1
fi

echo ""
echo "================================================"
echo "✅ 모든 리포지토리의 stg 브랜치가 최신 상태입니다!"
echo "================================================"
