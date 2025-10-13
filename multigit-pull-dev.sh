#!/bin/bash

# GLI Project - Pull latest changes from dev branch
# 모든 GLI 리포지토리의 dev 브랜치를 최신 상태로 업데이트

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
FAIL_REASONS=()

echo "================================================"
echo "GLI MultiGit: Pull Dev Branch"
echo "================================================"
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

  # Check if dev branch exists remotely
  if git ls-remote --heads origin dev | grep -q "dev"; then
    echo "🌿 원격 dev 브랜치가 존재합니다"

    # Check if dev branch exists locally
    if git show-ref --verify --quiet refs/heads/dev; then
      echo "  로컬 dev 브랜치 존재"
    else
      echo "  로컬 dev 브랜치 생성 중..."
      git checkout -b dev origin/dev > /dev/null 2>&1
    fi

    # Switch to dev and pull
    git checkout dev > /dev/null 2>&1

    if git pull origin dev; then
      echo "  ✅ Pull 성공"
      SUCCESS_REPOS+=("$REPO_NAME")
    else
      echo "  ❌ Pull 실패"
      FAILED_REPOS+=("$REPO_NAME")
      FAIL_REASONS+=("Pull failed")
    fi
  else
    echo "  ❌ 원격 dev 브랜치가 존재하지 않습니다"
    FAILED_REPOS+=("$REPO_NAME")
    FAIL_REASONS+=("Remote dev branch does not exist")
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
  for i in "${!FAILED_REPOS[@]}"; do
    echo "  - ${FAILED_REPOS[$i]}: ${FAIL_REASONS[$i]}"
  done
  exit 1
fi

echo ""
echo "================================================"
echo "모든 리포지토리의 dev 브랜치가 최신 상태입니다!"
echo "================================================"
