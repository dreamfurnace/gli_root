#!/bin/bash

# GLI Project - Merge dev to stg across all repositories
# dev → stg 머지를 모든 리포지토리에 일괄 적용
# 이 작업 후 자동으로 스테이징 환경에 배포됩니다

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
echo "GLI MultiGit: Merge dev → stg"
echo "================================================"
echo ""
echo "⚠️  주의: 이 작업은 stg 브랜치에 dev를 머지합니다."
echo "         스테이징 환경에 자동 배포됩니다."
echo ""
read -p "계속하시겠습니까? (yes 입력 필요): " -r
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

  # Ensure we're on the latest dev
  echo "  1️⃣ dev 브랜치로 전환 및 최신화..."
  git checkout dev > /dev/null 2>&1
  git pull origin dev > /dev/null 2>&1

  # Switch to stg and pull
  echo "  2️⃣ stg 브랜치로 전환 및 최신화..."
  git checkout stg > /dev/null 2>&1
  git pull origin stg > /dev/null 2>&1

  # Merge dev into stg
  echo "  3️⃣ dev → stg 머지 시도..."
  if git merge dev --no-ff --no-edit; then
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
  echo "⚠️  실패한 리포지토리의 충돌을 해결한 후 다시 실행하세요."
  exit 1
fi

echo ""
echo "================================================"
echo "✅ dev → stg 머지 완료!"
echo "🚀 스테이징 환경 배포가 시작되었습니다"
echo "   - stg.glibiz.com"
echo "   - stg-api.glibiz.com"
echo "   - stg-admin.glibiz.com"
echo "   - stg-ws.glibiz.com"
echo "================================================"
