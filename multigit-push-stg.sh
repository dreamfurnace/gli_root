#!/bin/bash

# GLI Project - Push stg branch across all repositories
# 모든 리포지토리의 stg 브랜치에 변경사항을 add, commit, push
# ⚠️  주의: 자동으로 커밋 및 푸시되어 스테이징 환경에 배포됩니다

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
SKIPPED_REPOS=()

echo "================================================"
echo "GLI MultiGit: Push stg branch"
echo "================================================"
echo ""
echo "⚠️  주의: 이 작업은 로컬 stg 브랜치를 원격에 푸시합니다."
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

  # Check if stg branch exists
  if ! git rev-parse --verify stg > /dev/null 2>&1; then
    echo "  ⚠️  stg 브랜치가 존재하지 않습니다. 건너뜁니다."
    SKIPPED_REPOS+=("$REPO_NAME (no stg branch)")
    cd - > /dev/null
    echo ""
    continue
  fi

  # Switch to stg branch
  echo "  1️⃣ stg 브랜치로 전환..."
  if ! git checkout stg > /dev/null 2>&1; then
    echo "  ❌ stg 브랜치로 전환 실패"
    FAILED_REPOS+=("$REPO_NAME")
    cd - > /dev/null
    echo ""
    continue
  fi

  # Check for changes (both uncommitted and unpushed)
  echo "  2️⃣ 변경사항 확인..."
  HAS_UNCOMMITTED=$(git status --porcelain 2>/dev/null)
  HAS_UNPUSHED=$(git log origin/stg..stg 2>/dev/null)

  if [ -z "$HAS_UNCOMMITTED" ] && [ -z "$HAS_UNPUSHED" ]; then
    echo "  ℹ️  변경사항이 없습니다. 건너뜁니다."
    SKIPPED_REPOS+=("$REPO_NAME (no changes)")
    cd - > /dev/null
    echo ""
    continue
  fi

  # Add all changes
  if [ -n "$HAS_UNCOMMITTED" ]; then
    echo "  3️⃣ 변경사항 staging..."
    # Remove .DS_Store files
    find . -name ".DS_Store" -delete 2>/dev/null || true
    if ! grep -q "^\.DS_Store$" .gitignore 2>/dev/null; then
      echo ".DS_Store" >> .gitignore
    fi
    git rm --cached .DS_Store 2>/dev/null || true

    git add -A
    echo "  ✅ staging 완료"

    # Commit changes
    echo "  4️⃣ 변경사항 커밋..."
    COMMIT_MSG="stg: auto commit and deploy

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"

    if git commit -m "$COMMIT_MSG" > /dev/null 2>&1; then
      echo "  ✅ 커밋 완료"
    else
      echo "  ⚠️  커밋할 변경사항 없음"
    fi
  fi

  # Push to remote
  echo "  5️⃣ 원격 저장소에 푸시..."
  if git push origin stg; then
    echo "  ✅ 푸시 성공 (스테이징 환경 배포 시작됨)"
    SUCCESS_REPOS+=("$REPO_NAME")
  else
    echo "  ❌ 푸시 실패"
    echo "  해결 방법:"
    echo "    cd $repo"
    echo "    git pull origin stg  # 원격 변경사항 먼저 가져오기"
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

if [ ${#SKIPPED_REPOS[@]} -gt 0 ]; then
  echo ""
  echo "⏭️  건너뛴 리포지토리 (${#SKIPPED_REPOS[@]}):"
  for repo in "${SKIPPED_REPOS[@]}"; do
    echo "  - $repo"
  done
fi

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
echo "✅ stg 브랜치 푸시 완료!"
echo "🚀 스테이징 환경 배포가 시작되었습니다"
echo "   - stg.glibiz.com"
echo "   - stg-api.glibiz.com"
echo "   - stg-admin.glibiz.com"
echo "   - stg-ws.glibiz.com"
echo "================================================"
