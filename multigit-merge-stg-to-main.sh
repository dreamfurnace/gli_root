#!/bin/bash

# GLI Project - Merge stg to main across all repositories
# stg → main 머지를 모든 리포지토리에 일괄 적용
# ⚠️  PRODUCTION 배포 스크립트 - 신중하게 사용!
# 사용법: ./multigit-merge-stg-to-main.sh ["커밋 메시지"]

set -e

# 커밋 메시지 (인자로 전달되지 않으면 기본 메시지 사용)
COMMIT_MSG="${1:-Merge stg into main (production deployment)}"

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
echo "GLI MultiGit: Merge stg → main (PRODUCTION)"
echo "================================================"
echo ""
echo "📝 커밋 메시지: $COMMIT_MSG"
echo ""
echo "🚨 경고: 이 작업은 PRODUCTION 환경에 배포됩니다!"
echo ""
echo "배포 전 체크리스트:"
echo "  ✅ 스테이징 환경에서 모든 기능이 정상 동작하는가?"
echo "  ✅ 데이터베이스 마이그레이션이 필요한가? (필요시 사전 작업)"
echo "  ✅ 중요 API 엔드포인트 테스트를 완료했는가?"
echo "  ✅ 사용자 프론트엔드와 관리자 대시보드를 테스트했는가?"
echo "  ✅ 배포 후 롤백 계획이 있는가?"
echo "  ✅ 팀원들에게 배포 일정을 공유했는가?"
echo ""
read -p "⚠️ 위 체크리스트를 모두 확인했으며 PRODUCTION 배포를 진행하시겠습니까? (yes 입력 필요): " -r
if [[ ! $REPLY == "yes" ]]; then
  echo "❌ 배포가 취소되었습니다"
  exit 1
fi

echo ""
echo "🚀 PRODUCTION 배포를 시작합니다..."
echo ""

# Create deployment tag
DEPLOY_TAG="deploy-$(date +%Y%m%d-%H%M%S)"
echo "📌 배포 태그 생성: $DEPLOY_TAG"
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

  # Ensure we're on the latest stg
  echo "  1️⃣ stg 브랜치로 전환 및 최신화..."
  git checkout stg > /dev/null 2>&1
  git pull origin stg > /dev/null 2>&1

  # Switch to main and pull
  echo "  2️⃣ main 브랜치로 전환 및 최신화..."
  git checkout main > /dev/null 2>&1
  git pull origin main > /dev/null 2>&1

  # Merge stg into main
  echo "  3️⃣ stg → main 머지 시도..."
  if git merge stg --no-ff -m "$COMMIT_MSG"; then
    echo "  ✅ 머지 성공"

    # Create deployment tag
    echo "  4️⃣ 배포 태그 생성..."
    git tag -a "$DEPLOY_TAG" -m "Production deployment on $(date)" > /dev/null 2>&1

    # Push to remote with tags
    echo "  5️⃣ 원격 저장소에 푸시 (태그 포함)..."
    if git push origin main && git push origin --tags; then
      echo "  ✅ 푸시 성공 (프로덕션 환경 배포 시작됨)"
      echo "  📌 태그: $DEPLOY_TAG"
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
    echo "    git tag -a '$DEPLOY_TAG' -m 'Production deployment'"
    echo "    git push origin main"
    echo "    git push origin --tags"
    FAILED_REPOS+=("$REPO_NAME")
  fi

  cd - > /dev/null
  echo ""
done

echo "================================================"
echo "Deployment Summary"
echo "================================================"
echo "📌 Deployment Tag: $DEPLOY_TAG"
echo ""
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
  echo "⚠️  실패한 리포지토리의 충돌을 해결한 후 수동으로 배포하세요."
  echo ""
  echo "롤백이 필요한 경우:"
  echo "  git checkout main"
  echo "  git reset --hard HEAD~1"
  echo "  git push origin main --force-with-lease"
  exit 1
fi

echo ""
echo "================================================"
echo "✅ stg → main 머지 완료!"
echo "🚀 PRODUCTION 환경 배포가 시작되었습니다"
echo ""
echo "배포된 환경:"
echo "  - glibiz.com (User Frontend)"
echo "  - api.glibiz.com (API Server)"
echo "  - admin.glibiz.com (Admin Dashboard)"
echo "  - ws.glibiz.com (WebSocket Server)"
echo ""
echo "다음 단계:"
echo "  1. GitHub Actions 워크플로우 확인"
echo "  2. 배포 완료 후 프로덕션 환경 테스트"
echo "  3. 모니터링 대시보드 확인"
echo "  4. 사용자 피드백 모니터링"
echo ""
echo "롤백이 필요한 경우 즉시 연락하세요!"
echo "================================================"

# Log deployment
echo "[$(date)] PRODUCTION DEPLOYMENT: $DEPLOY_TAG" >> deployment.log
echo "  Repositories: ${SUCCESS_REPOS[*]}" >> deployment.log
