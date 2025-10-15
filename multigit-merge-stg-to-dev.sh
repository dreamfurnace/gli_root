#!/bin/bash

# GLI Project - Merge stg to dev across all repositories
# stg → dev 머지를 모든 리포지토리에 일괄 적용
# 🔄 스테이징에서 검증된 내용을 개발 브랜치에 동기화
# 사용법: ./multigit-merge-stg-to-dev.sh ["커밋 메시지"]

set -e

# 커밋 메시지 (인자로 전달되지 않으면 기본 메시지 사용)
COMMIT_MSG="${1:-Merge stg into dev (sync verified)}"

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
echo "GLI MultiGit: Merge stg → dev (Sync Verified)"
echo "================================================"
echo ""
echo "📝 커밋 메시지: $COMMIT_MSG"
echo ""
echo "🔄 이 작업은 스테이징에서 검증된 내용을 개발 브랜치에 동기화합니다."
echo "   stg 브랜치의 변경사항을 dev 브랜치로 머지합니다."
echo ""
echo "사용 시나리오:"
echo "  - 스테이징에서 추가 수정/검증이 이루어진 경우"
echo "  - 스테이징에서 핫픽스를 받아서 dev에도 반영할 때"
echo "  - dev와 stg 브랜치를 동기화하고 싶을 때"
echo ""
read -p "stg의 내용을 dev로 동기화하시겠습니까? (yes 입력 필요): " -r
if [[ ! $REPLY == "yes" ]]; then
  echo "❌ 작업이 취소되었습니다"
  exit 1
fi

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

  # Check if branches exist
  if ! git rev-parse --verify stg > /dev/null 2>&1; then
    echo "  ⚠️  stg 브랜치가 존재하지 않습니다. 건너뜁니다."
    FAILED_REPOS+=("$REPO_NAME (no stg branch)")
    cd - > /dev/null
    echo ""
    continue
  fi

  if ! git rev-parse --verify dev > /dev/null 2>&1; then
    echo "  ⚠️  dev 브랜치가 존재하지 않습니다. 건너뜁니다."
    FAILED_REPOS+=("$REPO_NAME (no dev branch)")
    cd - > /dev/null
    echo ""
    continue
  fi

  # Ensure we're on the latest stg
  echo "  1️⃣ stg 브랜치로 전환 및 최신화..."
  git checkout stg > /dev/null 2>&1
  git pull origin stg > /dev/null 2>&1

  # Switch to dev and pull
  echo "  2️⃣ dev 브랜치로 전환 및 최신화..."
  git checkout dev > /dev/null 2>&1
  git pull origin dev > /dev/null 2>&1

  # Check if stg has changes that dev doesn't have
  COMMITS_BEHIND=$(git rev-list dev..stg --count 2>/dev/null || echo "0")

  if [ "$COMMITS_BEHIND" -eq 0 ]; then
    echo "  ℹ️  stg에서 가져올 새 커밋이 없습니다. 건너뜁니다."
    SUCCESS_REPOS+=("$REPO_NAME (already up-to-date)")
    cd - > /dev/null
    echo ""
    continue
  fi

  echo "  📝 stg에서 가져올 커밋: $COMMITS_BEHIND개"

  # Merge stg into dev
  echo "  3️⃣ stg → dev 머지 시도..."
  if git merge stg --no-ff -m "$COMMIT_MSG"; then
    echo "  ✅ 머지 성공"

    # Push to remote
    echo "  4️⃣ 원격 저장소에 푸시..."
    if git push origin dev; then
      echo "  ✅ 푸시 성공"
      SUCCESS_REPOS+=("$REPO_NAME")
    else
      echo "  ❌ 푸시 실패"
      FAILED_REPOS+=("$REPO_NAME")
    fi
  else
    echo "  ❌ 머지 충돌 발생! 수동으로 해결이 필요합니다."
    echo "  해결 방법:"
    echo "    cd $repo"
    echo "    git status"
    echo "    # 충돌 해결 후"
    echo "    git add ."
    echo "    git commit"
    echo "    git push origin dev"
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
  echo "⚠️  실패한 리포지토리의 충돌을 해결한 후 수동으로 푸시하세요."
  exit 1
fi

echo ""
echo "================================================"
echo "✅ stg → dev 머지 완료!"
echo "🔄 스테이징에서 검증된 내용이 dev에 동기화되었습니다"
echo ""
echo "다음 단계:"
echo "  1. dev 브랜치에서 추가 개발 작업 진행"
echo "  2. 완료 후 다시 dev → stg → main 순서로 배포"
echo "================================================"
