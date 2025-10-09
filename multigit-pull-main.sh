#!/usr/bin/env bash
set -euo pipefail

GITHUB_ORG="dreamfurnace"
REPOS=(
  .
  gli_redis
  gli_user-frontend
  gli_admin-frontend
  gli_api-server
  gli_database
  gli_rabbitmq
  gli_websocket
)

# 결과 추적 배열
SUCCESS_REPOS=()
FAILED_REPOS=()
FAIL_REASONS=()

# 반드시 GLI 루트에서 실행하세요
# cd /path/to/gli_root

for repo in "${REPOS[@]}"; do
  echo
  echo "====== $repo ======"

  # 1) 폴더가 있되 .git이 없으면 지우고
  if [ -d "$repo" ] && [ ! -d "$repo/.git" ]; then
    echo "⚠️ $repo 에 .git 이 없으므로 삭제 후 재클론합니다"
    rm -rf "$repo"
  fi

  # 2) 폴더가 없으면 clone
  if [ ! -d "$repo" ]; then
    echo "📥 Cloning $repo..."
    if ! git clone "git@github.com:$GITHUB_ORG/$repo.git" "$repo"; then
      echo "❌ Clone 실패"
      FAILED_REPOS+=("$repo")
      FAIL_REASONS+=("Clone 실패")
      continue
    fi
  fi

  # 3) pull 전에 로컬 변경 감지
  if [ -n "$(git -C "$repo" status --porcelain)" ]; then
    echo "⚠️ [$repo] 로컬 변경사항이 존재합니다. 먼저 커밋하거나 스태시하세요."
    FAILED_REPOS+=("$repo")
    FAIL_REASONS+=("로컬 변경사항 존재")
    continue
  fi

  # 4) main 브랜치 존재 여부 확인 및 생성/전환
  cd "$repo"

  # 에러 처리를 위한 플래그
  REPO_SUCCESS=true
  REPO_FAIL_REASON=""

  # 원격 브랜치 정보 가져오기
  echo "🔄 원격 브랜치 정보 업데이트 중..."
  if ! git fetch origin; then
    echo "❌ fetch 실패"
    REPO_SUCCESS=false
    REPO_FAIL_REASON="Fetch 실패"
  fi

  # 성공한 경우에만 계속 진행
  if [ "$REPO_SUCCESS" = true ]; then
    # 원격 main 브랜치가 존재하는지 확인
    if git ls-remote --heads origin main | grep -q "main"; then
      echo "🌿 원격 main 브랜치가 존재합니다"

      # 로컬 main 브랜치 존재 확인
      if git show-ref --verify --quiet refs/heads/main; then
        echo "🔄 기존 main 브랜치로 전환 중..."
        if ! git checkout main; then
          REPO_SUCCESS=false
          REPO_FAIL_REASON="main 브랜치 체크아웃 실패"
        elif ! git pull origin main; then
          REPO_SUCCESS=false
          REPO_FAIL_REASON="Pull 실패"
        fi
      else
        echo "🆕 원격 main 브랜치를 기준으로 로컬 main 브랜치 생성 중..."
        if ! git checkout -b main origin/main; then
          REPO_SUCCESS=false
          REPO_FAIL_REASON="main 브랜치 생성 실패"
        fi
      fi
    else
      echo "❌ 원격에 main 브랜치가 없습니다"
      REPO_SUCCESS=false
      REPO_FAIL_REASON="원격 main 브랜치 없음"
    fi
  fi

  # 결과 기록
  if [ "$REPO_SUCCESS" = true ]; then
    SUCCESS_REPOS+=("$repo")
    echo "✅ [$repo] 성공"
  else
    FAILED_REPOS+=("$repo")
    FAIL_REASONS+=("$REPO_FAIL_REASON")
    echo "❌ [$repo] 실패: $REPO_FAIL_REASON"
  fi

  cd - > /dev/null
done

echo
echo "==============================================="
echo "📊 멀티깃 Pull 결과 보고"
echo "==============================================="
echo "✅ 성공한 저장소 (${#SUCCESS_REPOS[@]}개):"
if [ ${#SUCCESS_REPOS[@]} -gt 0 ]; then
  for repo in "${SUCCESS_REPOS[@]}"; do
    echo "   - $repo"
  done
else
  echo "   (없음)"
fi

echo
echo "❌ 실패한 저장소 (${#FAILED_REPOS[@]}개):"
if [ ${#FAILED_REPOS[@]} -gt 0 ]; then
  for i in "${!FAILED_REPOS[@]}"; do
    echo "   - ${FAILED_REPOS[$i]}: ${FAIL_REASONS[$i]}"
  done
else
  echo "   (없음)"
fi

echo
if [ ${#FAILED_REPOS[@]} -gt 0 ]; then
  echo "🔧 실패한 저장소 처리 방법:"
  echo "   1. 로컬 변경사항이 있는 경우: git add . && git commit 또는 git stash"
  echo "   2. 네트워크 문제: 잠시 후 다시 실행"
  echo "   3. 권한 문제: SSH 키 설정 확인"
  echo
  echo "⚠️ 실패한 저장소가 있습니다. 문제를 해결한 후 다시 실행하세요."
  exit 1
else
  echo "🎉 모든 저장소가 성공적으로 업데이트되었습니다!"
fi
