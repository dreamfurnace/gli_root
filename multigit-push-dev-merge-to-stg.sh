#!/bin/bash

# GLI Project - Push dev and merge to stg across all repositories
# dev 브랜치에 변경사항을 커밋/푸시하고, stg 브랜치로 머지
# 🚀 개발 완료 → 스테이징 배포까지 한 번에 처리
# 사용법: ./multigit-push-dev-merge-to-stg.sh "커밋 메시지"

set -e

# 커밋 메시지 (인자로 전달되지 않으면 기본 메시지 사용)
COMMIT_MSG="${1:-dev: auto commit and merge to staging}"

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
echo "GLI MultiGit: dev → stg 배포"
echo "================================================"
echo "📝 커밋 메시지: $COMMIT_MSG"
echo "⚠️  dev 커밋 → stg 머지 → 스테이징 배포"
echo ""
read -p "계속하시겠습니까? (yes 입력 필요): " -r
if [[ ! $REPLY == "yes" ]]; then
  echo "❌ 작업 취소"
  exit 1
fi

# Create staging deployment tag
STG_DEPLOY_TAG="stg-deploy-$(date +%Y%m%d-%H%M%S)"
echo "📌 배포 태그: $STG_DEPLOY_TAG"
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

  # Check if dev branch exists
  if ! git rev-parse --verify dev > /dev/null 2>&1; then
    echo "  ⚠️  dev 브랜치가 존재하지 않습니다. 건너뜁니다."
    SKIPPED_REPOS+=("$REPO_NAME (no dev branch)")
    cd - > /dev/null
    echo ""
    continue
  fi

  # Step 1: Handle dev branch
  echo "  📝 dev 브랜치 처리 중..."
  if ! git checkout dev > /dev/null 2>&1; then
    echo "  ❌ dev 브랜치로 전환 실패"
    FAILED_REPOS+=("$REPO_NAME")
    cd - > /dev/null
    echo ""
    continue
  fi

  # Skip pull for now (can cause hang issues)
  # Check for uncommitted changes
  HAS_UNCOMMITTED=$(git status --porcelain 2>/dev/null)

  if [ -n "$HAS_UNCOMMITTED" ]; then
    echo "     변경사항 발견 - 커밋 & 푸시 진행..."

    # Remove .DS_Store files
    find . -name ".DS_Store" -delete 2>/dev/null || true
    if ! grep -q "^\.DS_Store$" .gitignore 2>/dev/null; then
      echo ".DS_Store" >> .gitignore
    fi
    git rm --cached .DS_Store 2>/dev/null || true

    git add -A
    if git commit -m "$COMMIT_MSG" > /dev/null 2>&1; then
      if ! git push origin dev; then
        echo "  ❌ dev 푸시 실패"
        FAILED_REPOS+=("$REPO_NAME")
        cd - > /dev/null
        echo ""
        continue
      fi
      echo "     ✅ 커밋 & 푸시 완료"
    else
      echo "     ⚠️  커밋할 변경사항 없음"
    fi
  else
    echo "     변경사항 없음 - 머지 진행"
  fi

  # Step 2: Merge dev to stg
  echo "  🚀 stg 브랜치 머지 & 배포..."
  if ! git checkout stg > /dev/null 2>&1; then
    echo "  ❌ stg 브랜치로 전환 실패"
    FAILED_REPOS+=("$REPO_NAME")
    cd - > /dev/null
    echo ""
    continue
  fi

  git pull origin stg > /dev/null 2>&1

  # Merge dev into stg
  MERGE_MSG="Merge dev into stg: $COMMIT_MSG"
  if git merge dev --no-ff -m "$MERGE_MSG"; then
    # Create staging deployment tag and push
    git tag -a "$STG_DEPLOY_TAG" -m "Staging deployment on $(date)" > /dev/null 2>&1
    if git push origin stg && git push origin --tags; then
      echo "     ✅ 머지 완료 & 스테이징 배포 시작 (태그: $STG_DEPLOY_TAG)"
      SUCCESS_REPOS+=("$REPO_NAME")
    else
      echo "  ❌ stg 푸시 실패"
      FAILED_REPOS+=("$REPO_NAME")
    fi
  else
    echo "  ❌ 머지 충돌! 수동 해결 필요: cd $repo && git status"
    FAILED_REPOS+=("$REPO_NAME")
  fi

  cd - > /dev/null
  echo ""
done

echo "================================================"
echo "배포 결과 (태그: $STG_DEPLOY_TAG)"
echo "================================================"
echo "✅ 성공 (${#SUCCESS_REPOS[@]}): ${SUCCESS_REPOS[*]}"

if [ ${#SKIPPED_REPOS[@]} -gt 0 ]; then
  echo "⏭️  건너뜀 (${#SKIPPED_REPOS[@]}): ${SKIPPED_REPOS[*]}"
fi

if [ ${#FAILED_REPOS[@]} -gt 0 ]; then
  echo "❌ 실패 (${#FAILED_REPOS[@]}): ${FAILED_REPOS[*]}"
  echo "⚠️  실패한 리포지토리를 확인하세요."
  exit 1
fi

echo ""
echo "🚀 스테이징 환경 배포 완료!"
echo "   stg.glibiz.com | stg-api.glibiz.com | stg-admin.glibiz.com | stg-ws.glibiz.com"
echo "================================================"
