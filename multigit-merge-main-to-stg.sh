#!/bin/bash

# GLI Project - Merge main to stg across all repositories
# main → stg 머지를 모든 리포지토리에 일괄 적용
# 🔧 프로덕션 핫픽스를 스테이징에 반영할 때 사용

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
echo "GLI MultiGit: Merge main → stg (Hotfix Sync)"
echo "================================================"
echo ""
echo "🔧 이 작업은 프로덕션 핫픽스를 스테이징에 반영합니다."
echo "   main 브랜치의 변경사항을 stg 브랜치로 머지합니다."
echo ""
echo "⚠️  주의사항:"
echo "  - 일반적인 개발 흐름: dev → stg → main"
echo "  - 이 스크립트는 역방향: main → stg (핫픽스 전용)"
echo "  - 프로덕션에서 긴급 수정한 내용을 스테이징에 동기화할 때만 사용"
echo ""
read -p "핫픽스를 스테이징에 반영하시겠습니까? (yes 입력 필요): " -r
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

  # Ensure we're on the latest main
  echo "  1️⃣ main 브랜치로 전환 및 최신화..."
  git checkout main > /dev/null 2>&1
  git pull origin main > /dev/null 2>&1

  # Switch to stg and pull
  echo "  2️⃣ stg 브랜치로 전환 및 최신화..."
  git checkout stg > /dev/null 2>&1
  git pull origin stg > /dev/null 2>&1

  # Check if main has changes that stg doesn't have
  COMMITS_BEHIND=$(git rev-list stg..main --count 2>/dev/null || echo "0")

  if [ "$COMMITS_BEHIND" -eq 0 ]; then
    echo "  ℹ️  main에서 가져올 새 커밋이 없습니다. 건너뜁니다."
    SUCCESS_REPOS+=("$REPO_NAME (already up-to-date)")
    cd - > /dev/null
    echo ""
    continue
  fi

  echo "  📝 main에서 가져올 커밋: $COMMITS_BEHIND개"

  # Merge main into stg
  echo "  3️⃣ main → stg 머지 시도..."
  if git merge main --no-edit; then
    echo "  ✅ 머지 성공"

    # Push to remote
    echo "  4️⃣ 원격 저장소에 푸시..."
    if git push origin stg; then
      echo "  ✅ 푸시 성공 (스테이징 환경 배포 시작됨)"
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
    echo "    git push origin stg"
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
echo "✅ main → stg 머지 완료!"
echo "🔧 프로덕션 핫픽스가 스테이징에 반영되었습니다"
echo "🚀 스테이징 환경 배포가 시작되었습니다"
echo ""
echo "다음 단계:"
echo "  1. 스테이징 환경에서 핫픽스 검증"
echo "  2. dev 브랜치도 동기화 필요시:"
echo "     ./multigit-merge-main-to-dev.sh (필요시 생성)"
echo "================================================"
