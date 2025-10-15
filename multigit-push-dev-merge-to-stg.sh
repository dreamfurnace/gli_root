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
echo "GLI MultiGit: Push dev → Merge to stg"
echo "================================================"
echo ""
echo "📝 커밋 메시지: $COMMIT_MSG"
echo ""
echo "⚠️  주의: 이 작업은 다음을 수행합니다:"
echo "  1. dev 브랜치의 변경사항을 커밋 & 푸시"
echo "  2. dev를 stg로 머지"
echo "  3. stg를 원격에 푸시 (스테이징 환경 배포)"
echo ""
read -p "계속하시겠습니까? (yes 입력 필요): " -r
if [[ ! $REPLY == "yes" ]]; then
  echo "❌ 작업이 취소되었습니다"
  exit 1
fi

echo ""

# Create staging deployment tag
STG_DEPLOY_TAG="stg-deploy-$(date +%Y%m%d-%H%M%S)"
echo "📌 스테이징 배포 태그 생성: $STG_DEPLOY_TAG"
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
  echo "  1️⃣ dev 브랜치로 전환..."
  if ! git checkout dev > /dev/null 2>&1; then
    echo "  ❌ dev 브랜치로 전환 실패"
    FAILED_REPOS+=("$REPO_NAME")
    cd - > /dev/null
    echo ""
    continue
  fi

  # Pull latest dev
  echo "  2️⃣ dev 브랜치 최신화..."
  git pull origin dev > /dev/null 2>&1

  # Check for uncommitted changes
  echo "  3️⃣ dev 브랜치 변경사항 확인..."
  HAS_UNCOMMITTED=$(git status --porcelain 2>/dev/null)

  if [ -n "$HAS_UNCOMMITTED" ]; then
    echo "  4️⃣ dev 브랜치 변경사항 staging..."
    # Remove .DS_Store files
    find . -name ".DS_Store" -delete 2>/dev/null || true
    if ! grep -q "^\.DS_Store$" .gitignore 2>/dev/null; then
      echo ".DS_Store" >> .gitignore
    fi
    git rm --cached .DS_Store 2>/dev/null || true

    git add -A
    echo "  ✅ staging 완료"

    # Commit changes
    echo "  5️⃣ dev 브랜치 커밋..."
    if git commit -m "$COMMIT_MSG" > /dev/null 2>&1; then
      echo "  ✅ 커밋 완료"
    else
      echo "  ⚠️  커밋할 변경사항 없음"
    fi

    # Push to remote dev
    echo "  6️⃣ dev 브랜치 푸시..."
    if ! git push origin dev; then
      echo "  ❌ dev 푸시 실패"
      FAILED_REPOS+=("$REPO_NAME")
      cd - > /dev/null
      echo ""
      continue
    fi
    echo "  ✅ dev 푸시 성공"
  else
    echo "  ℹ️  dev 브랜치에 uncommitted 변경사항 없음"
  fi

  # Step 2: Merge dev to stg
  echo "  7️⃣ stg 브랜치로 전환 및 최신화..."
  if ! git checkout stg > /dev/null 2>&1; then
    echo "  ❌ stg 브랜치로 전환 실패"
    FAILED_REPOS+=("$REPO_NAME")
    cd - > /dev/null
    echo ""
    continue
  fi
  git pull origin stg > /dev/null 2>&1

  # Merge dev into stg
  echo "  8️⃣ dev → stg 머지 시도..."
  MERGE_MSG="Merge dev into stg: $COMMIT_MSG"
  if git merge dev --no-ff -m "$MERGE_MSG"; then
    echo "  ✅ 머지 성공"

    # Create staging deployment tag
    echo "  9️⃣ 스테이징 배포 태그 생성..."
    git tag -a "$STG_DEPLOY_TAG" -m "Staging deployment on $(date)" > /dev/null 2>&1

    # Push to remote stg with tags
    echo "  🔟 stg 브랜치 푸시 (태그 포함)..."
    if git push origin stg && git push origin --tags; then
      echo "  ✅ 푸시 성공 (스테이징 환경 배포 시작됨)"
      echo "  📌 태그: $STG_DEPLOY_TAG"
      SUCCESS_REPOS+=("$REPO_NAME")
    else
      echo "  ❌ stg 푸시 실패"
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
    echo "    git tag -a '$STG_DEPLOY_TAG' -m 'Staging deployment'"
    echo "    git push origin stg"
    echo "    git push origin --tags"
    FAILED_REPOS+=("$REPO_NAME")
  fi

  cd - > /dev/null
  echo ""
done

echo "================================================"
echo "Deployment Summary"
echo "================================================"
echo "📌 Staging Deployment Tag: $STG_DEPLOY_TAG"
echo ""
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
echo "✅ dev 커밋/푸시 → stg 머지 완료!"
echo "🚀 스테이징 환경 배포가 시작되었습니다"
echo ""
echo "배포된 환경:"
echo "  - stg.glibiz.com"
echo "  - stg-api.glibiz.com"
echo "  - stg-admin.glibiz.com"
echo "  - stg-ws.glibiz.com"
echo "================================================"
